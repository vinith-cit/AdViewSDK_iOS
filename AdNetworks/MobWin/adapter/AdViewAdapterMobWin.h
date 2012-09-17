/*
 
 Copyright 2010 www.adview.cn. All rights reserved.
 
 */

#import "AdViewAdNetworkAdapter.h"
#import "MobWinBannerViewDelegate.h"

@interface AdViewAdapterMobWin : AdViewAdNetworkAdapter <MobWinBannerViewDelegate> {
	
}

+ (AdViewAdNetworkType)networkType;

@end
