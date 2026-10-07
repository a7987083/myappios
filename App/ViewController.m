#import "ViewController.h"
#import "ZSignEngine.h"

typedef NS_ENUM(NSInteger, PickKind) {
    PickKindIPA,
    PickKindP12,
    PickKindProvision
};

@interface ViewController () <UIDocumentPickerDelegate>
@property (nonatomic, strong) UILabel *ipaLabel;
@property (nonatomic, strong) UILabel *p12Label;
@property (nonatomic, strong) UILabel *provisionLabel;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UIButton *signButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, copy) NSString *ipaPath;
@property (nonatomic, copy) NSString *p12Path;
@property (nonatomic, copy) NSString *provisionPath;
@property (nonatomic) PickKind pickKind;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"IPA 签名";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    UILabel *desc = [UILabel new];
    desc.numberOfLines = 0;
    desc.text = @"zsign iOS 13 原型\n选择 IPA、P12 和 mobileprovision 后直接重签。";
    [stack addArrangedSubview:desc];

    [stack addArrangedSubview:[self button:@"选择 IPA" action:@selector(selectIPA)]];
    self.ipaLabel = [self infoLabel:@"未选择 IPA"];
    [stack addArrangedSubview:self.ipaLabel];

    [stack addArrangedSubview:[self button:@"选择 P12" action:@selector(selectP12)]];
    self.p12Label = [self infoLabel:@"未选择 P12"];
    [stack addArrangedSubview:self.p12Label];

    [stack addArrangedSubview:[self button:@"选择 mobileprovision" action:@selector(selectProvision)]];
    self.provisionLabel = [self infoLabel:@"未选择 mobileprovision"];
    [stack addArrangedSubview:self.provisionLabel];

    self.passwordField = [[UITextField alloc] init];
    self.passwordField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordField.placeholder = @"P12 密码";
    self.passwordField.secureTextEntry = YES;
    [stack addArrangedSubview:self.passwordField];

    self.signButton = [self button:@"开始签名" action:@selector(sign)];
    [stack addArrangedSubview:self.signButton];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    [stack addArrangedSubview:self.spinner];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24]
    ]];
}

- (UIButton *)button:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UILabel *)infoLabel:(NSString *)text {
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:13];
    label.textColor = UIColor.secondaryLabelColor;
    label.numberOfLines = 2;
    label.text = text;
    return label;
}

- (void)selectIPA { self.pickKind = PickKindIPA; [self openPicker]; }
- (void)selectP12 { self.pickKind = PickKindP12; [self openPicker]; }
- (void)selectProvision { self.pickKind = PickKindProvision; [self openPicker]; }

- (void)openPicker {
    UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"]
                                                               inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;

    switch (self.pickKind) {
        case PickKindIPA:
            self.ipaPath = url.path;
            self.ipaLabel.text = url.lastPathComponent;
            break;
        case PickKindP12:
            self.p12Path = url.path;
            self.p12Label.text = url.lastPathComponent;
            break;
        case PickKindProvision:
            self.provisionPath = url.path;
            self.provisionLabel.text = url.lastPathComponent;
            break;
    }
}

- (void)sign {
    if (!self.ipaPath.length || !self.p12Path.length || !self.provisionPath.length) {
        [self alert:@"请先选择 IPA、P12 和 mobileprovision"];
        return;
    }

    self.signButton.enabled = NO;
    [self.spinner startAnimating];

    NSString *name = [NSString stringWithFormat:@"signed-%@.ipa", NSUUID.UUID.UUIDString];
    NSString *output = [NSHomeDirectory() stringByAppendingPathComponent:
                        [@"Documents" stringByAppendingPathComponent:name]];

    NSString *ipa = self.ipaPath;
    NSString *p12 = self.p12Path;
    NSString *prov = self.provisionPath;
    NSString *pwd = self.passwordField.text ?: @"";

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        BOOL ok = [ZSignEngine signIPAAtPath:ipa
                                     p12Path:p12
                                    password:pwd
                               provisionPath:prov
                                  outputPath:output
                                       error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.signButton.enabled = YES;
            [self.spinner stopAnimating];

            if (!ok) {
                [self alert:error.localizedDescription ?: @"签名失败"];
                return;
            }

            NSURL *fileURL = [NSURL fileURLWithPath:output];
            UIActivityViewController *share =
                [[UIActivityViewController alloc] initWithActivityItems:@[fileURL]
                                                  applicationActivities:nil];
            if (share.popoverPresentationController) {
                share.popoverPresentationController.sourceView = self.signButton;
            }
            [self presentViewController:share animated:YES completion:nil];
        });
    });
}

- (void)alert:(NSString *)message {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"myappios"
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
