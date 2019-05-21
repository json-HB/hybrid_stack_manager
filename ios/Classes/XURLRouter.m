//
//  XURLRouter.m
//  Runner
//
//  Created by KyleWong on 2018/8/13.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

#import "XURLRouter.h"
#import "XFlutterModule.h"

@implementation XURLRouter
+ (instancetype)sharedInstance {
    static XURLRouter *sInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [XURLRouter new];
    });
    return sInstance;
}
@end

void XOpenURLWithQueryAndParams(NSString *url, NSDictionary *query, NSDictionary *params) {
    NSURL *tmpUrl = [NSURL URLWithString:url];
    if (tmpUrl.scheme == nil || (![tmpUrl.scheme isEqualToString:kOpenUrlPrefix] && ![tmpUrl.scheme hasPrefix:@"http"])) {
        return;
    }
    if ([tmpUrl.scheme hasPrefix:@"http"] || [@"native" isEqualToString:tmpUrl.host]) {
        NativeOpenUrlHandler handler = [XURLRouter sharedInstance].nativeOpenUrlHandler;
        if (handler != nil) {
            handler(url, query, params);
        }
    } else {
        [[XFlutterModule sharedInstance] openURL:url query:query params:params];
    }
}
