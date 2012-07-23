/*
 
 Adview .
 2012-04-12
 */

#import "AdViewAdNetworkAdapter.h"
#import "MobWinBannerViewDelegate.h"

@interface AdViewAdapterMobWin : AdViewAdNetworkAdapter <MobWinBannerViewDelegate> {
	
}

+ (AdViewAdNetworkType)networkType;

@end
