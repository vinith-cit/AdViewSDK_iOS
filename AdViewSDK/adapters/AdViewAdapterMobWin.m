/*
 
 Adview .
 2012-04-12
 */

#import "AdViewAdapterMobWin.h"
#import "MobWinBannerView.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewViewImpl.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "SingletonAdapterBase.h"

@interface AdViewAdapterMobWinImpl : SingletonAdapterBase <MobWinBannerViewDelegate> {
}

@end

static AdViewAdapterMobWinImpl *gMobWinImpl = nil;


@implementation AdViewAdapterMobWin

+ (AdViewAdNetworkType)networkType {
	return AdViewAdNetworkTypeMobWin;
}

+ (void)load {
	if(NSClassFromString(@"MobWinBannerView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	AWLogInfo(@"MobWin getAd");
	
	Class MobWinBannerViewClass = NSClassFromString (@"MobWinBannerView");
	
	if (nil == MobWinBannerViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no mobwin lib support, can not create.");
		return;
	}
	
	if (nil == gMobWinImpl) gMobWinImpl = [[AdViewAdapterMobWinImpl alloc] init];
	[gMobWinImpl setAdapterValue:YES ByAdapter:self];
	
	MobWinBannerView *adBanner = (MobWinBannerView*)[gMobWinImpl getIdelAdView];
	if (nil == adBanner) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}
	
	self.adNetworkView = adBanner;
	[adBanner startRequest];
	//[adViewView adapter:self didReceiveAdView:adBanner];
	[adBanner release];
}

- (void)stopBeingDelegate {
	MobWinBannerView *adBanner = (MobWinBannerView *)self.adNetworkView;
	AWLogInfo(@"mobwin stop being delegate");
	[gMobWinImpl setAdapterValue:NO ByAdapter:self];
	if (adBanner != nil) {
		[adBanner stopRequest];
#if 0
		[gMobWinImpl addIdelAdView:adBanner];
		[adBanner removeFromSuperview];
#endif
		self.adNetworkView = nil;
	}
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
				self.nSizeAd = MobWINBannerSizeIdentifierUnknow;
				break;
			case AdviewBannerSize_300x250:
				self.nSizeAd = MobWINBannerSizeIdentifier300x250;
				break;
			case AdviewBannerSize_480x60:
				self.nSizeAd = MobWINBannerSizeIdentifier468x60;
				break;
			case AdviewBannerSize_728x90:
				self.nSizeAd = MobWINBannerSizeIdentifier728x90;
				break;
		}
	} else if (isIPad) {
		self.nSizeAd = MobWINBannerSizeIdentifier728x90;
	} else {
		self.nSizeAd = MobWINBannerSizeIdentifierUnknow;
	}
}

- (void)dealloc {
	[super dealloc];
}

@end

@implementation AdViewAdapterMobWinImpl

#pragma mark util

- (NSString *)appId {
	NSString *apID;
	if ([mAdapter.adViewDelegate respondsToSelector:@selector(MobWinAppIDString)]) {
		apID = [mAdapter.adViewDelegate MobWinAppIDString];
	}
	else {
		apID = mAdapter.networkConfig.pubId;
	}
    
	return apID;
	//return @"A495798C12C030F28E7711F3613DFC1B";
}

- (UIView*)createAdView {
	Class MobWinBannerViewClass = NSClassFromString (@"MobWinBannerView");
	
	if (nil == MobWinBannerViewClass) {
		[mAdapter.adViewView adapter:mAdapter didFailAd:nil];
		AWLogInfo(@"no mobwin lib support, can not create.");
		return nil;
	}
	
	[mAdapter updateSizeParameter];
	MobWinBannerView *adBanner = [[MobWinBannerViewClass alloc] 
								  initMobWinBannerSizeIdentifier:mAdapter.nSizeAd];
	if (nil == adBanner)
		return nil;
	
	adBanner.delegate = self;
	adBanner.rootViewController = [mAdapter.adViewDelegate viewControllerForPresentingModalView];
	adBanner.adUnitID = [self appId];
	//
	// 腾讯MobWIN提示：开发者可选调用
	//
	adBanner.adGpsMode = [mAdapter helperUseGpsMode];
	
	//adBanner.adTextColor = [mAdapter helperTextColorToUse];
	//adBanner.adSubtextColor = [mAdapter helperSecondaryTextColorToUse];
	//adBanner.adBackgroundColor = [mAdapter helperBackgroundColorToUse];

	mAdapter.adNetworkView = adBanner;
	//[adBanner startRequest];
	return adBanner;
}

#pragma mark MobWinDelegate methods

// 详解:请求插播广告成功时调用
- (void)bannerViewDidReceived {
	AWLogInfo(@"mobwin bannerViewDidReceived");
	if (nil == mAdapter) return;
	[mAdapter.adViewView adapter:mAdapter didReceiveAdView:mAdapter.adNetworkView];
}
 
// 详解:请求插播广告失败时调用
- (void)bannerViewFailToReceived {
	AWLogInfo(@"mobwin bannerViewFailToReceived");
	if (nil == mAdapter) return;
	[mAdapter.adViewView adapter:mAdapter didFailAd:nil];
}

// 详解:将要展示一次插播广告内容前调用
- (void)bannerViewDidPresentScreen {
	AWLogInfo(@"mobwin bannerViewDidPresentScreen");
	[mAdapter helperNotifyDelegateOfFullScreenModal];
}

// 详解:插播广告展示完成，结束插播广告后调用
- (void)bannerViewDidDismissScreen {
	AWLogInfo(@"mobwin bannerViewDidDismissScreen");
	[mAdapter helperNotifyDelegateOfFullScreenModalDismissal];
}

@end
