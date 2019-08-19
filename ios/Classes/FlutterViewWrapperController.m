//
//  FlutterViewWrapperController.m
//  Runner
//
//  Created by 正物 on 08/03/2018.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

#import <Flutter/FlutterChannels.h>
#import "FlutterViewWrapperController.h"
#import "HybridStackManager.h"

#import "UIImage+GIF.h"
typedef NS_ENUM(NSInteger, FlutterVCSwitchCategory) {
    FlutterVCSwitchCategoryOK,
};

typedef void (^FlutterWrapperHandleBlock)();

@interface FlutterViewWrapperController ()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIImageView *fakeSnapImgView;
@property (nonatomic, strong) UIImage *lastSnapshot;
@property (nonatomic, copy) NSString *lastFlutterRouteName;

//add screen white bug fix

@property(nonatomic,weak) id<UIGestureRecognizerDelegate> originalGestureDelegate;



//新增（wayne）
@property (nonatomic, strong) UIImageView *loadingImageView;
@end

@implementation FlutterViewWrapperController

#pragma mark - loadingView
- (UIImageView *)loadingImageView
{
    if (_loadingImageView == nil) {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        _loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake((window.bounds.size.width-60)/2, (window.bounds.size.height-60-64)/2, 60, 60)];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"loading" ofType:@"gif"];
        NSData *data = [NSData dataWithContentsOfFile:path];
        UIImage *image = [UIImage sd_imageWithGIFData:data];
        _loadingImageView.image = image;
    }
    return _loadingImageView;
}

#pragma mark - LifeCycle
- (instancetype)initWithURL:(NSURL *)url query:(NSDictionary *)query nativeParams:(NSDictionary *)nativeParams {
    self = [super initWithURL:url query:query nativeParams:nativeParams];
    if (self) {
    }
    return self;
}

- (void)loadView {
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor whiteColor]];
    self.view = view;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return TRUE;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.fakeSnapImgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.fakeSnapImgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.fakeSnapImgView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.fakeSnapImgView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    XFlutterViewController *flutterVC = [FlutterViewWrapperController flutterVC];
    if([[flutterVC parentViewController] isEqual:self]) {
        [flutterVC didReceiveMemoryWarning];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    //add screen white bug fix
    self.navigationController.navigationBarHidden = TRUE;
    self.originalGestureDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;

    
    if (self.viewWillAppearBlock) {
        self.viewWillAppearBlock();
        self.viewWillAppearBlock = nil;
    }
    if (!self.lastSnapshot) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addChildFlutterVC];
        });
    }
    
    [self.view addSubview:self.loadingImageView];
    [self performSelector:@selector(removeLoadingImageView) withObject:nil afterDelay:10];
}

- (void)removeLoadingImageView
{
    [self.loadingImageView removeFromSuperview];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self addChildFlutterVC];
    if (self.curFlutterRouteName.length && self.lastSnapshot) {
        [[HybridStackManager sharedInstance].methodChannel invokeMethod:@"popToRouteNamed" arguments:self.curFlutterRouteName];
    }
    [[FlutterViewWrapperController flutterVC].view setUserInteractionEnabled:TRUE];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    UINavigationController *rootNav = (UINavigationController*)[UIApplication sharedApplication].delegate.window.rootViewController;
    //add screen white bug fix
    rootNav.interactivePopGestureRecognizer.delegate = self.originalGestureDelegate;

    
    NSArray *curStackAry = rootNav.viewControllers;
    NSInteger idx = [curStackAry indexOfObject:self];
    if (idx != NSNotFound && idx != curStackAry.count - 1) {
        [self saveSnapshot];
    }
    [[FlutterViewWrapperController flutterVC].view setUserInteractionEnabled:FALSE];
    // TODO: 手势返回过程中标题栏有半透遮罩，暂时不处理
    // if (![rootNav.topViewController isKindOfClass:[FlutterViewWrapperController class]]) {
    //     [self.navigationController setNavigationBarHidden:NO animated:NO];
    // }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    UINavigationController *rootNav = (UINavigationController*)[UIApplication sharedApplication].delegate.window.rootViewController;
    NSArray *ary = [rootNav.viewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *, id> * _Nullable bindings) {
        if ([evaluatedObject isKindOfClass:[FlutterViewWrapperController class]]) {
            return TRUE;
        } else {
            return FALSE;
        }
    }]];
    if (!ary.count) {
        [[HybridStackManager sharedInstance].methodChannel invokeMethod:@"popToRoot" arguments:nil];
    }
    
    NSArray *curStackAry = rootNav.viewControllers;
    NSInteger idx = [curStackAry indexOfObject:self];
    if (idx == NSNotFound) {
        [[HybridStackManager sharedInstance].methodChannel invokeMethod:@"popRouteNamed" arguments:self.lastFlutterRouteName];
    }
}

#pragma mark - Child/Parent VC
- (void)showFlutterViewOverSnapshot {
    XFlutterViewController *flutterVC = [FlutterViewWrapperController flutterVC];
    BOOL priorIsMyChild = (flutterVC.parentViewController == self);
    if (self.lastSnapshot) {
        [self.view bringSubviewToFront:self.fakeSnapImgView];
    }
    flutterVC.view.frame = self.view.bounds;
    flutterVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view bringSubviewToFront:flutterVC.view];
        self.lastSnapshot = nil;
    });
}

- (void)addChildFlutterVC {
    XFlutterViewController *flutterVC = [FlutterViewWrapperController flutterVC];
    if (self == flutterVC.parentViewController) {
        [self showFlutterViewOverSnapshot];
        return;
    }
    if (nil != flutterVC.parentViewController) {
        [self removeChildFlutterVC];
    }
    [self.view addSubview:flutterVC.view];
    [self addChildViewController:flutterVC];
    [self showFlutterViewOverSnapshot];
}

- (void)removeChildFlutterVC {
    XFlutterViewController *flutterVC = [FlutterViewWrapperController flutterVC];
    //Remove VC
    [flutterVC removeFromParentViewController];
    [flutterVC.view removeFromSuperview];
}

- (void)saveSnapshot {
    XFlutterViewController *flutterVC = [FlutterViewWrapperController flutterVC];
    if (flutterVC.parentViewController != self) {
        return;
    }
    if (self.lastSnapshot == nil) {
        UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, 0);
        [flutterVC.view drawViewHierarchyInRect:flutterVC.view.bounds afterScreenUpdates:NO];
        self.lastSnapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self.fakeSnapImgView setImage:self.lastSnapshot];
        [self.view bringSubviewToFront:self.fakeSnapImgView];
    }
}

+ (XFlutterViewController *)flutterVC {
    static XFlutterViewController *sxFlutterVC;
    if (sxFlutterVC) {
        return sxFlutterVC;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sxFlutterVC = [[XFlutterViewController alloc] initWithProject:nil nibName:nil bundle:nil];
    });
    return sxFlutterVC;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return TRUE;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer{
    return TRUE;
}

@end
