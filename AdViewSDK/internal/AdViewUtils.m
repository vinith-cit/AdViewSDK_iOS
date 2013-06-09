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
#import "adViewAdNetworkConfig.h"

@implementation AdViewUtils

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code.
    }
    return self;
}

+ (NSString *)nstringFixNil:(NSString *)str {
    if (str) return str;
    return @"";
}

+ (NSDictionary*)getPlatformsForKey:(NSString*)adViewKey
{
    AdViewConfig *config = [[AdViewConfigStore sharedStore] getBufferConfig:adViewKey];
    if (nil == config) return nil;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
    for (AdViewAdNetworkConfig *adNetConfig in config.adNetworkConfigs)
    {
        if (adNetConfig.trafficPercentage <= 0.0) continue;
        
        NSString *val = [NSString stringWithFormat:@"%@,%d,%d,%@,%@,%@",
                         adNetConfig.networkName, (int)adNetConfig.trafficPercentage,
                         adNetConfig.priority,
                         [AdViewUtils nstringFixNil:adNetConfig.pubId],
                         [AdViewUtils nstringFixNil:adNetConfig.pubId2],
                         [AdViewUtils nstringFixNil:adNetConfig.pubId3]];
        [dict setObject:val forKey:[NSNumber numberWithInt:adNetConfig.networkType]];
    }
    
    return dict;
}

+ (NSDictionary*)getAdPlatforms {
	return [[AdViewAdNetworkRegistry sharedRegistry] getClassesStatus];
}

+ (void)setAdPlatformStatus:(NSDictionary*)dict		//dict like upper.
{
	[[AdViewAdNetworkRegistry sharedRegistry] setClassesStatus:dict];
	[[AdViewConfigStore sharedStore] setNeedParseConfig];
}

- (void)dealloc {
    [super dealloc];
}


@end
