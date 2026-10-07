#import "ZSignEngine.h"

#include "archive.h"
#include "bundle.h"
#include "openssl.h"

#include <string>
#include <vector>

using std::string;
using std::vector;

static NSError *ZSignMakeError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:@"com.zonoe.myappios.zsign"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message ?: @"Unknown zsign error"}];
}

@implementation ZSignEngine

+ (BOOL)signIPAAtPath:(NSString *)ipaPath
              p12Path:(NSString *)p12Path
             password:(NSString *)password
        provisionPath:(NSString *)provisionPath
           outputPath:(NSString *)outputPath
                error:(NSError **)error {

    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *work = [NSTemporaryDirectory() stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"zsign-%@", NSUUID.UUID.UUIDString]];

    if (![fm createDirectoryAtPath:work withIntermediateDirectories:YES attributes:nil error:error]) {
        return NO;
    }

    BOOL success = NO;

    @try {
        if (!Zip::Extract(ipaPath.fileSystemRepresentation, work.fileSystemRepresentation)) {
            if (error) *error = ZSignMakeError(1001, @"IPA 解包失败");
            return NO;
        }

        ZSignAsset asset;
        if (!asset.Init("",
                        p12Path.fileSystemRepresentation,
                        provisionPath.fileSystemRepresentation,
                        "",
                        password.UTF8String ?: "",
                        false,
                        true,
                        false)) {
            if (error) *error = ZSignMakeError(1002, @"P12 / Provisioning Profile 初始化失败");
            return NO;
        }

        ZBundle bundle;
        bundle.m_bEnableDocuments = false;
        bundle.m_strMinVersion = "";
        bundle.m_strIconFile = "";
        bundle.m_bRemoveExtensions = false;
        bundle.m_bRemoveWatchApp = false;
        bundle.m_bRemoveUISupportedDevices = false;
        bundle.m_bInjectExtensions = false;

        vector<string> injectDylibs;
        vector<string> removeDylibs;

        if (!bundle.SignFolder(&asset,
                               work.fileSystemRepresentation,
                               "",
                               "",
                               "",
                               injectDylibs,
                               removeDylibs,
                               true,
                               false,
                               false,
                               false)) {
            if (error) *error = ZSignMakeError(1003, @"zsign Bundle 签名失败");
            return NO;
        }

        NSString *parent = outputPath.stringByDeletingLastPathComponent;
        if (![fm createDirectoryAtPath:parent withIntermediateDirectories:YES attributes:nil error:error]) {
            return NO;
        }

        if (!Zip::Archive(work.fileSystemRepresentation,
                          outputPath.fileSystemRepresentation,
                          5)) {
            if (error) *error = ZSignMakeError(1004, @"签名完成，但 IPA 回包失败");
            return NO;
        }

        success = YES;
        return YES;
    }
    @finally {
        [fm removeItemAtPath:work error:nil];
        if (!success && error && !*error) {
            *error = ZSignMakeError(1099, @"签名失败");
        }
    }
}

@end
