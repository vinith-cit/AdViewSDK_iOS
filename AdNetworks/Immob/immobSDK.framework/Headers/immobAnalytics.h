//
//  immobAdSDK.h
//  immobAdSDK
//
//  Created by sun rui on 12-8-21.
//  Copyright (c) 2012年 sun rui. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol immobAnalyticsDelegate <UIApplicationDelegate>

-(void)applicationDidActivate:(NSString *)creativeID;

@end

@interface immobAnalytics : NSObject

+ (void) sendRequest:(NSString *)creativeID;

@end
