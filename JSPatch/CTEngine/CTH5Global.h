//
//  CTH5Global.h
//  CTBusiness
//
//  Created by jim on 15/11/18.
//  Copyright © 2015年 Ctrip. All rights reserved.
//

#import <Foundation/Foundation.h>


//Package prefix
#define kiOSHotFixPackagePrefix [@"hf_iOS" stringByAppendingFormat:@"_%@", getAppVersion()]
#define kTempiOSHotFixPackagePrefix [@"hf_iOS" stringByAppendingFormat:@"_%@_tmp", getAppVersion()]

//Notifications
#define kH5WebViewShouldReloadNotification @"kH5WebViewShouldReloadNotification"
#define kH5NativeShouldReloadNotification @"kH5NativeShouldReloadNotification"
#define kH5CopyStringNotification @"kH5CopyStringNotification"
#define kFileDidChangedNotification @"kFileDidChangedNotification"

//UserDefaults Keys
#define kLocalDebugFlagKey @"kLocalDebugFlagKey"
#define kShowH5LogFlagKey @"kShowH5LogFlagKey"


#define kIs_Debug_Local boolValueForKey(kLocalDebugFlagKey)

#define  kDPath          [kDocumentDir stringByAppendingString:@"/d.x"]
#define  kCPath          [kDocumentDir stringByAppendingString:@"/c.x"]
#define  kWebappDirPrefixName @"webapp_work"
#define  kWbDownloadDirPrefixName @"wb-download"
#define  kWebAppDirName [kWebappDirPrefixName stringByAppendingFormat:@"_%@", [CRNDefine appDisplayVersion]]
#define  kWbDownloadDirName [kWbDownloadDirPrefixName stringByAppendingFormat:@"-%@", [CRNDefine appDisplayVersion]]
#define  kOldWebAppDir [kDocumentDir stringByAppendingPathComponent:@"webapp_work"]
//#define  kWebAppDirPath [kDocumentDir stringByAppendingFormat:@"/%@/",kWebAppDirName]
#define  kDebugWebAppDirName @"webapp"
#define  kWebAppCacheDirName @"wb_cache"

#define  kWbDownloadDirPath [kDocumentDir stringByAppendingFormat:@"/%@/",kWbDownloadDirName]


@interface CTH5Global : NSObject


@property (nonatomic, copy) NSString *h5WebViewCallbackString;
//@property (nonatomic, strong) NSDictionary *crnViewCallbackData;

+ (void)loadHotFixScriptInWorkDir;
+ (void)loadHotFixScriptForAppStart;

+(void)downScriptInQNiu;
@end
