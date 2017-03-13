
//
//  CTH5Common.m
//  CTBusiness
//
//  Created by jim on 15/11/18.
//  Copyright © 2015年 Ctrip. All rights reserved.
//

#import "CTH5Global.h"

#import "CTEngine.h"
#import <Foundation/Foundation.h>
#define kCtripUAFlag @"_CtripWireless"
#define kPadAppFlag @"_Ctrip_Pad_App_"
#define kBase64EncodeParamFlag @"eb64"
#import "AFNetworking.h"
#import "YYModel.h"
static BOOL isStartEngine = NO;
static NSMutableSet *injectHistorySet = nil;
static NSDictionary *g_originalWebappDict = nil;

@implementation CTH5Global


+ (void)startCTEngineIfNeed {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!isStartEngine) {
            isStartEngine = YES;
            injectHistorySet = [NSMutableSet set];
            [CTXXXEngine startXXXEngine];
        }
    });
}

+ (void)loadHotFixScriptForAppStart {
    [self loadHotFixScriptInWorkDir];
    
}

// 判断文件是否存在
+ (BOOL)isExistsFilePath:(NSString *)filePath
{
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        return YES;
    }
    
    return NO;
}

// 读取string
+ (NSString *)readWithContentsOfFile:(NSString *)filePath
{
    NSString *str = @"";
    
    if([CTH5Global isExistsFilePath:filePath])
    {
        str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];;
    }
    
    return str;
}


+(void)downScriptInQNiu
{
    NSString *url =@"http://omqp9pe49.bkt.clouddn.com/vbkConfig.json";
    [[AFHTTPSessionManager manager]GET:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
}

+ (void)loadHotFixScriptInWorkDir {
    [CTXXXEngine startXXXEngine];
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [[NSBundle mainBundle]pathForResource:@"main.js" ofType:nil];
    NSString *testScript = [CTH5Global readWithContentsOfFile:path];
    [CTXXXEngine evaluateXXXScript:testScript];
    return;
    
//    NSString *hotfixWorkDir = [CTH5URL getHybridModulePath:kiOSHotFixPackagePrefix];
//    NSError *error = NULL;
//    NSArray *fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:hotfixWorkDir error:&error];
//    
//    if (error == NULL && [fileList count] > 0) {
//        [self startCTEngineIfNeed];
//        
//        for (NSString *aFile in fileList) {
//            NSString *fullPath = [hotfixWorkDir stringByAppendingPathComponent:aFile];
//            if ([injectHistorySet containsObject:fullPath]) { //inject already
//                continue;
//            }
//            
//            [injectHistorySet addObject:fullPath];  //性能考虑，app生命周期，只inject一次
//            
//            NSData *scriptData = [NSData dataWithContentsOfFile:fullPath];
//            if (scriptData != NULL) {
//                NSData *decriptData = [CTDataCrypt ctripDecryptData:scriptData];
//                if (decriptData != NULL) {
//                    NSString *scriptStr = [[NSString alloc] initWithData:decriptData encoding:NSUTF8StringEncoding];
//                    if (scriptStr.length > 0) {
//                        [CTXXXEngine evaluateXXXScript:scriptStr];
//                    }
//                } else {
//                    remove([fullPath UTF8String]);
//                }
//            }
//        }
//    }
}






//+ (NSDictionary *)localHybridPackagesVersionInfo {
//    if (g_originalWebappDict == nil) {
//        NSError *error = nil;
//        NSString *versionFilePath = [[kAppDir stringByAppendingPathComponent:kWebappNameInPackage] stringByAppendingPathComponent:@"version.config"];
//        NSString *versionJSONStr = [NSString stringWithContentsOfFile:versionFilePath
//                                                             encoding:NSUTF8StringEncoding
//                                                                error:&error];
//        g_originalWebappDict = [versionJSONStr objectFromJSONStringForCtrip];
//    }
//
//    return g_originalWebappDict;
//}
//
//+ (NSString *)versionInfoForPackage:(NSString *)pkgName {
//    if (g_originalWebappDict == nil) {
//        [CTH5Global localHybridPackagesVersionInfo];
//    }
//    return [g_originalWebappDict valueForKey:pkgName];
//}

@end
