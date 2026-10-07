#import "SettingsViewController.h"

typedef NS_ENUM(NSInteger, SettingsSection) {
    SettingsSectionSigning = 0,
    SettingsSectionStorage,
    SettingsSectionAbout,
    SettingsSectionCount
};

@interface SettingsViewController ()
@property (nonatomic, copy) NSArray<NSArray<NSDictionary *> *> *items;
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"设置";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;

    self.items = @[
        @[
            @{@"title": @"证书管理",
              @"subtitle": @"管理 P12、mobileprovision 与默认使用证书",
              @"icon": @"person.crop.rectangle"},
            @{@"title": @"默认签名参数",
              @"subtitle": @"Bundle ID、版本号、名称与签名选项",
              @"icon": @"signature"},
            @{@"title": @"签名输出",
              @"subtitle": @"默认保存到 Documents",
              @"icon": @"folder"}
        ],
        @[
            @{@"title": @"清理临时文件",
              @"subtitle": @"删除签名过程中产生的临时目录",
              @"icon": @"trash"}
        ],
        @[
            @{@"title": @"关于",
              @"subtitle": @"版本与构建信息",
              @"icon": @"info.circle"},
            @{@"title": @"开源许可",
              @"subtitle": @"第三方组件与许可证",
              @"icon": @"doc.text"}
        ]
    ];

    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"SettingsCell"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SettingsSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SettingsSectionSigning: return @"签名";
        case SettingsSectionStorage: return @"文件";
        case SettingsSectionAbout: return @"应用";
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell"];
    NSDictionary *item = self.items[indexPath.section][indexPath.row];

    if (@available(iOS 14.0, *)) {
        UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
        content.text = item[@"title"];
        content.secondaryText = item[@"subtitle"];
        content.image = [UIImage systemImageNamed:item[@"icon"]];
        cell.contentConfiguration = content;
    } else {
        cell.textLabel.text = item[@"title"];
        cell.detailTextLabel.text = item[@"subtitle"];
        cell.imageView.image = [UIImage systemImageNamed:item[@"icon"]];
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (indexPath.section == SettingsSectionStorage && indexPath.row == 0) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == SettingsSectionStorage && indexPath.row == 0) {
        [self clearTemporaryFiles];
        return;
    }

    if (indexPath.section == SettingsSectionAbout && indexPath.row == 0) {
        [self showAbout];
        return;
    }

    NSString *title = self.items[indexPath.section][indexPath.row][@"title"];
    [self showPlaceholder:title];
}

- (void)clearTemporaryFiles {
    NSString *tmp = NSTemporaryDirectory();
    NSFileManager *fm = NSFileManager.defaultManager;
    NSArray<NSString *> *contents = [fm contentsOfDirectoryAtPath:tmp error:nil];

    for (NSString *name in contents) {
        NSString *path = [tmp stringByAppendingPathComponent:name];
        [fm removeItemAtPath:path error:nil];
    }

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"已清理"
                                            message:@"临时文件已删除。"
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                             style:UIAlertActionStyleDefault
                                           handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAbout {
    NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0";
    NSString *build = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"1";

    NSString *message = [NSString stringWithFormat:@"myappios\n版本 %@ (%@)\n最低支持 iOS 13", version, build];

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"关于"
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                             style:UIAlertActionStyleDefault
                                           handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showPlaceholder:(NSString *)title {
    UIViewController *vc = [UIViewController new];
    vc.title = title;
    vc.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.secondaryLabelColor;
    label.text = [NSString stringWithFormat:@"%@\n下一阶段接入实际功能", title];

    [vc.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:vc.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:vc.view.centerYAnchor],
        [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:vc.view.leadingAnchor constant:24],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:vc.view.trailingAnchor constant:-24]
    ]];

    [self.navigationController pushViewController:vc animated:YES];
}

@end
