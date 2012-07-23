/*

 AdViewView.h

 Copyright 2010 www.adview.cn. All rights reserved.

*/

#import <UIKit/UIKit.h>

@interface AdViewUtils : NSObject
{
}

+ (NSDictionary*)getAdPlatforms;	//NSString-NSNumber, number is type, string is "name,enable", like "AdMob,1"
+ (void)setAdPlatformStatus:(NSDictionary*)dict;		//NSNumber-NSNumber, key is type, value is enable, 0--disable.

@end