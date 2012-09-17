//
//  FtadSdk.h
//  FtadSdkIos3Lib
//
//  Created by Verna on 11-12-19.
//  Copyright 2011年 www.adview.cn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FtadSdk : NSObject {
    
}

//
//
+(void)initSdkConfig:(NSString*)pid;
//
//
+(void)releaseSdkConfig;
//
//
+(void)setNeedFullScreenStartView:(BOOL)isneed;
//
//
+(BOOL)isNeedFullScreenStartView;
//
//
+(void)setNeedInsertView:(BOOL)isneed;
//
//
+(BOOL)isneedInsertView;
//
//
+(void)setNeedLocation:(BOOL)isneed;
//
//
+(BOOL)isNeedLocation;
//
//
+(void)updateLocationWithLatitudeAndLongitude:(double)latitude longitude:(double)longitude;
//
//
+(void)setRootViewController:(id)root;
//
//
+(id)getRootViewController;
//
//
+(void)setClickViewFullScreen:(BOOL)isCan;
//
//
+(BOOL)canClickViewFullScreen;

@end
