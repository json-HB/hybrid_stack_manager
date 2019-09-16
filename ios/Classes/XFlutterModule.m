//
//  XFlutterModule.m
//  FleaMarket
//
//  Created by 正物 on 2018/03/08.
//  Copyright © 2017 正物. All rights reserved.
//

#import "XFlutterModule.h"
#import "HybridStackManager.h"

@interface XFlutterModule() {
    BOOL _isInFlutterRootPage;
    bool _isFlutterWarmedup;
}
@end

@implementation XFlutterModule
@synthesize isInFlutterRootPage = _isInFlutterRootPage;

#pragma mark - XModuleProtocol
+ (instancetype)sharedInstance {
    static XFlutterModule *sXFlutterModule;
    if(sXFlutterModule) {
        return sXFlutterModule;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sXFlutterModule = [[[self class] alloc] initInstance];
        [sXFlutterModule warmupFlutter];
    });
    return sXFlutterModule;
}

- (instancetype)initInstance {
    self = [super init];
    if (self) {
        _isInFlutterRootPage = TRUE;
    }
    return self;
}

- (XFlutterViewController *)flutterVC {
    return [FlutterViewWrapperController flutterVC];
}

- (void)warmupFlutter {
    if (_isFlutterWarmedup) {
        return;
    }
    XFlutterViewController *flutterVC = [FlutterViewWrapperController flutterVC];
    [flutterVC view];
    [NSClassFromString(@"GeneratedPluginRegistrant") performSelector:NSSelectorFromString(@"registerWithRegistry:") withObject:flutterVC];
    _isFlutterWarmedup = true;
}

+ (NSDictionary *)parseParamsKV:(NSString *)aParamsStr {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *kvAry = [aParamsStr componentsSeparatedByString:@"&"];
    for (NSString *kv in kvAry) {
        NSArray *ary = [kv componentsSeparatedByString:@"="];
        if (ary.count == 2) {
            NSString *key = ary.firstObject;
            NSString *value = [ary.lastObject stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [dict setValue:value forKey:key];
        }
    }
    return dict;
}

- (void)openURL:(NSString *)aUrl query:(NSDictionary *)query params:(NSDictionary *)params {
    static BOOL sIsFirstPush = TRUE;
    //Process aUrl and Query Stuff.
    NSURL *url = [NSURL URLWithString:aUrl];
    
    NSMutableDictionary *mQuery = [NSMutableDictionary dictionaryWithDictionary:query];
    [mQuery addEntriesFromDictionary:[XFlutterModule parseParamsKV:url.query]];
    NSMutableDictionary *mParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [mParams addEntriesFromDictionary:[XFlutterModule parseParamsKV:url.parameterString]];
    NSString *pageUrl = [NSString stringWithFormat:@"%@://%@",url.scheme,url.host];
    
    FlutterMethodChannel *methodChann = [HybridStackManager sharedInstance].methodChannel;
    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    [arguments setValue:pageUrl forKey:@"url"];
    [arguments setValue:mQuery forKey:@"query"];
    [arguments setValue:mParams forKey:@"params"];
    [arguments setValue:@(0) forKey:@"animated"];
    
    //Push
//    UINavigationController *currentNavigation = (UINavigationController*)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    UITabBarController *tabVC = (UITabBarController*)[UIApplication sharedApplication].delegate.window.rootViewController;
    UINavigationController *currentNavigation = (UINavigationController *)tabVC.viewControllers[tabVC.selectedIndex];
    
    FlutterViewWrapperController *viewController = [[FlutterViewWrapperController alloc] initWithURL:[NSURL URLWithString:aUrl] query:mQuery nativeParams:mParams];
    
    viewController.viewWillAppearBlock = ^() {
        //Process first & later message sending according distinguishly.
        if (sIsFirstPush) {
            [HybridStackManager sharedInstance].mainEntryParams = arguments;
            sIsFirstPush = FALSE;
        } else {
            [methodChann invokeMethod:@"openURLFromFlutter" arguments:arguments result:^(id  _Nullable result) {
            }];
        }
    };
    [currentNavigation pushViewController:viewController animated:YES]; 
}

#pragma mark - XFlutterModuleProtocol
@end
