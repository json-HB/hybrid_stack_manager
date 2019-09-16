#import <sys/utsname.h>
#import "HybridStackManager.h"
#import "FlutterViewWrapperController.h"
#import "XURLRouter.h"

@interface HybridStackManager()
@property (nonatomic,strong) NSObject<FlutterPluginRegistrar>* registrar;
@end

@implementation HybridStackManager
+ (instancetype)sharedInstance {
    static HybridStackManager *sharedInst;
    if (sharedInst) {
        return sharedInst;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [[HybridStackManager alloc] init];
    });
    return sharedInst;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    HybridStackManager *instance = [HybridStackManager sharedInstance];
    instance.methodChannel = [FlutterMethodChannel
                              methodChannelWithName:@"hybrid_stack_manager"
                              binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:instance.methodChannel];
    instance.registrar = registrar;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"openUrlFromNative" isEqualToString:call.method]) {
        NSDictionary *openUrlInfo = call.arguments;
        XOpenURLWithQueryAndParams(openUrlInfo[@"url"], openUrlInfo[@"query"], openUrlInfo[@"params"]);
    } else if ([@"getMainEntryParams" isEqualToString:call.method]) {
        NSDictionary *params = self.mainEntryParams?:@{};
        if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] == NSOrderedAscending) {
            NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
            NSMutableDictionary *mutParams = [NSMutableDictionary dictionaryWithDictionary:params];
            params=mutParams;
        }
        result(params);
        //      self.mainEntryParams = nil;
    } else if ([@"updateCurPageFlutterRoute" isEqualToString:call.method]) {
        NSString *curRouteName = call.arguments;
//        UINavigationController *rootNav = (UINavigationController*)[UIApplication sharedApplication].delegate.window.rootViewController;
//        UIViewController *topVC = rootNav.topViewController;
        
        
        UITabBarController *tabVC = (UITabBarController*)[UIApplication sharedApplication].delegate.window.rootViewController;
        UINavigationController *rootNav = (UINavigationController *)tabVC.viewControllers[tabVC.selectedIndex];
        UIViewController *topVC = rootNav.topViewController;
        
        if ([topVC isKindOfClass:[FlutterViewWrapperController class]]) {
            FlutterViewWrapperController *flutterVC = topVC;
            [flutterVC setCurFlutterRouteName:curRouteName];
        }
    } else if ([@"popCurPage" isEqualToString:call.method]) {
        BOOL animated = YES;
        if (call.arguments && [call.arguments isKindOfClass:[NSNumber class]]) {
            animated = [(NSNumber *)call.arguments boolValue];
        }
        
//        UINavigationController *nav = (UINavigationController*)[UIApplication sharedApplication].delegate.window.rootViewController;
        
        UITabBarController *tabVC = (UITabBarController*)[UIApplication sharedApplication].delegate.window.rootViewController;
        UINavigationController *nav = (UINavigationController *)tabVC.viewControllers[tabVC.selectedIndex];
        
        if ([nav.topViewController isKindOfClass:[FlutterViewWrapperController class]]) {
            [nav popViewControllerAnimated:animated];
        }
    } else if ([@"toggleGestureBack" isEqualToString:call.method]) {
        BOOL enable = YES;
        if (call.arguments && [call.arguments isKindOfClass:[NSNumber class]]) {
            enable = [(NSNumber *)call.arguments boolValue];
        }
        XFlutterViewController *flutterVC = [FlutterViewWrapperController flutterVC];
        flutterVC.navigationController.interactivePopGestureRecognizer.enabled = enable;
    } else if ([@"callNativeMethod" isEqualToString:call.method]) {
        [XURLRouter sharedInstance].nativeFlutterCallHandler(result, call.arguments[@"method"], call.arguments[@"params"]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}
@end
