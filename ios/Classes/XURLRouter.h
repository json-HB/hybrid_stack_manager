//
//  XURLRouter.h
//  Runner
//
//  Created by KyleWong on 2018/8/13.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#define kOpenUrlPrefix  @"hrd"

typedef void (^NativeOpenUrlHandler)(NSString *, NSDictionary *, NSDictionary *);
typedef void (^NativeFlutterCallHandler)(FlutterResult , NSString *, NSDictionary *);

void XOpenURLWithQueryAndParams(NSString *url, NSDictionary *query, NSDictionary *params);

@interface XURLRouter : NSObject
@property (nonatomic, weak) NativeOpenUrlHandler nativeOpenUrlHandler;
@property (nonatomic, weak) NativeFlutterCallHandler nativeFlutterCallHandler;
+ (instancetype)sharedInstance;
@end
