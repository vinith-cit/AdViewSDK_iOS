//
//  AdViewUtils.m
//  AdViewSDK
//
//  Created by zhiwen on 12-7-5.
//  Copyright 2012 www.adview.cn. All rights reserved.
//

#import "AdViewUtils.h"
#import "adViewAdNetworkRegistry.h"
#import "adViewConfigStore.h"

@implementation AdViewUtils

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code.
    }
    return self;
}

+ (NSDictionary*)getAdPlatforms {
	return [[AdViewAdNetworkRegistry sharedRegistry] getClassesStatus];
}

+ (void)setAdPlatformStatus:(NSDictionary*)dict		//dict like upper.
{
	[[AdViewAdNetworkRegistry sharedRegistry] setClassesStatus:dict];
	[AdViewConfigStore sharedStore].needParseAgain = YES;
}

- (void)dealloc {
    [super dealloc];
}


@end
