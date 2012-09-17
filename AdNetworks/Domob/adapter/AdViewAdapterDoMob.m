/*
 
 Copyright 2010 www.adview.cn. All rights reserved.
 
 */

#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewDelegateProtocol.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "DMTools.h"
#import "AdViewAdapterDoMob.h"
#import "SingletonAdapterBase.h"

#define TestUserSpot @"all"

@interface AdViewAdapterDoMob ()
- (NSString *)appIdForAd;
@end

@interface AdViewAdapterDomobImpl : SingletonAdapterBase <DMAdViewDelegate> 

@end

static AdViewAdapterDomobImpl *gDomobImpl = nil;


@implementation AdViewAdapterDoMob

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeDOMOB;
}

+ (void)load {
	if(NSClassFromString(@"DMAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	Class dMAdViewClass = NSClassFromString (@"DMAdView");
	
	if (nil == dMAdViewClass) {
		AWLogInfo(@"no domob lib, can not create.");		
		[adViewView adapter:self didFailAd:nil];
		return;
	}
	
	if (nil == gDomobImpl) gDomobImpl = [[AdViewAdapterDomobImpl alloc] init];
	[gDomobImpl setAdapterValue:YES ByAdapter:self];
	DMAdView* adView = (DMAdView*)[gDomobImpl getIdelAdView];
	if (nil == adView) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}
	
	self.adNetworkView = adView;
    [adView loadAd]; // 开始加载广告
    
    // 检查更新提
#if 0
	Class dmToolsClass = NSClassFromString (@"DMTools");
	if (nil != dmToolsClass) {
		DMTools *dmTools = [[DMTools alloc] initWithPublisherId:[self appIdForAd]];
		[dmTools checkRateInfo];
		[dmTools release];
	}
#endif
    [adView release];
    [self setupDefaultDummyHackTimer];
}

- (void)stopBeingDelegate {
  DMAdView *adView = (DMAdView *)self.adNetworkView;
	AWLogInfo(@"--Domob stopBeingDelegate--");
	[gDomobImpl setAdapterValue:NO ByAdapter:self];
	[self cleanupDummyHackTimer];
	
  if (adView != nil) {
	  adView.delegate = nil;
	  adView.rootViewController = nil;
  }
	self.adNetworkView = nil;
}

- (void)cleanupDummyRetain {
	[gDomobImpl setAdapterValue:NO ByAdapter:self];
	[super cleanupDummyRetain];
}

- (void)updateSizeParameter {
	BOOL isIPad = [AdViewAdNetworkAdapter helperIsIpad];
	
	AdviewBannerSize	sizeId = AdviewBannerSize_Auto;
	if ([adViewDelegate respondsToSelector:@selector(PreferBannerSize)]) {
		sizeId = [adViewDelegate PreferBannerSize];
	}
	
	if (sizeId > AdviewBannerSize_Auto) {
		switch (sizeId) {
			case AdviewBannerSize_320x50:
				self.sSizeAd = DOMOB_AD_SIZE_320x50;
				break;
			case AdviewBannerSize_300x250:
				self.sSizeAd = DOMOB_AD_SIZE_300x250;
				break;
			case AdviewBannerSize_480x60:
				self.sSizeAd = DOMOB_AD_SIZE_488x80;
				break;
			case AdviewBannerSize_728x90:
				self.sSizeAd = DOMOB_AD_SIZE_728x90;
				break;
			default:
				break;
		}
	} else if (isIPad) {
		self.sSizeAd = DOMOB_AD_SIZE_728x90;
	} else {
		self.sSizeAd = DOMOB_AD_SIZE_320x50;
	}
}

- (void)dealloc {
  [super dealloc];
}

- (NSString *)appIdForAd {
	NSString *apID;
	if ([adViewDelegate respondsToSelector:@selector(DoMobApIDString)]) {
		apID = [adViewDelegate DoMobApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
	return apID;
	
	//return @"56OJycJIuMWsQqo0JM";
}

@end

@implementation AdViewAdapterDomobImpl

- (UIView*)createAdView {
	Class dMAdViewClass = NSClassFromString (@"DMAdView");
	
	if (nil == dMAdViewClass) {
		AWLogInfo(@"no domob lib, can not create.");
		return nil;
	}
	
	if (nil == mAdapter) {
		AWLogInfo(@"have not set domob adapter.");
		return nil;
	}
	
	AdViewAdapterDoMob *adapter = (AdViewAdapterDoMob*)mAdapter;
	
	[adapter updateSizeParameter];
	DMAdView* adView = [[dMAdViewClass alloc] initWithPublisherId:[adapter appIdForAd]
															 size:adapter.sSizeAd
													  autorefresh:NO];
	if (nil == adView) {
		AWLogInfo(@"did not alloc DMAdView");
		return nil;
	}
	
    adView.delegate = self; // 设置 Delegate
    adView.rootViewController = [mAdapter.adViewDelegate viewControllerForPresentingModalView];
	
	return adView;
}

#pragma mark DoMobDelegate methods

// 成功加载广告后，回调该方法
- (void)dmAdViewSuccessToLoadAd:(DMAdView *)adView
{
    AWLogInfo(@"Domob success to load ad.");
	
	if (![self isAdViewValid:adView]) return;
	
    [mAdapter cleanupDummyHackTimer];
	[mAdapter.adViewView adapter:mAdapter didReceiveAdView:adView];
}

// 加载广告失败后，回调该方法
- (void)dmAdViewFailToLoadAd:(DMAdView *)adView withError:(NSError *)error
{
    AWLogInfo(@"Domob fail to load ad. %@", error);
	
	if (![self isAdViewValid:adView]) return;
	
    [mAdapter cleanupDummyHackTimer];
	[mAdapter.adViewView adapter:mAdapter didFailAd:nil];
}

// 当将要呈现出 Modal View 时，回调该方法。如打开内置浏览器。
- (void)dmWillPresentModalViewFromAd:(DMAdView *)adView
{
    AWLogInfo(@"Domob will present modal view.");    
	[mAdapter helperNotifyDelegateOfFullScreenModal];
}

// 当呈现的 Modal View 被关闭后，回调该方法。如内置浏览器被关闭。
- (void)dmDidDismissModalViewFromAd:(DMAdView *)adView
{
    AWLogInfo(@"Domob did dismiss modal view.");
	[mAdapter helperNotifyDelegateOfFullScreenModalDismissal];
}

@end
