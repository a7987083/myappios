#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZSignEngine : NSObject

+ (BOOL)signIPAAtPath:(NSString *)ipaPath
              p12Path:(NSString *)p12Path
             password:(NSString *)password
        provisionPath:(NSString *)provisionPath
           outputPath:(NSString *)outputPath
                error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
