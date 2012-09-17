/*
 
 Copyright 2010 www.adview.cn. All rights reserved.
 
 */

#import "AdViewAdapterMobWin.h"
#import "MobWinBannerView.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewViewImpl.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "SingletonAdapterBase.h"
#import "AdviewObjCollector.h"

@interface AdViewAdapterMobWin()
- (UIView*)createAdView;
@end


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
	
	MobWinBannerView *adBanner = (MobWinBannerView*)[self createAdView];
	if (nil == adBanner) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}
	
	self.adNetworkView = adBanner;
    self.bWaitAd = YES;
	[adBanner startRequest];
	//[adViewView adapter:self didReceiveAdView:adBanner];
	[adBanner release];
}

- (void)stopBeingDelegate {
	MobWinBannerView *adBanner = (MobWinBannerView *)self.adNetworkView;
	AWLogInfo(@"mobwin stop being delegate");
	if (adBanner != nil) {
		[adBanner stopRequest];
		self.adNetworkView = nil;
	}
}

- (void)cleanupDummyRetain {
    [super cleanupDummyRetain];
    
    self.adViewView = nil;
    
    if (self.bWaitAd)
        [[AdviewObjCollector sharedCollector] addObj:self];
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
			default:
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

#pragma mark util

- (NSString *)appId {
	NSString *apID;
	if ([self.adViewDelegate respondsToSelector:@selector(MobWinAppIDString)]) {
		apID = [self.adViewDelegate MobWinAppIDString];
	}
	else {
		apID = self.networkConfig.pubId;
	}
    
	return apID;
	//return @"A495798C12C030F28E7711F3613DFC1B";
}

- (UIView*)createAdView {
	Class MobWinBannerViewClass = NSClassFromString (@"MobWinBannerView");
	
	if (nil == MobWinBannerViewClass) {
		[self.adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no mobwin lib support, can not create.");
		return nil;
	}
	
	[self updateSizeParameter];
	MobWinBannerView *adBanner = [[MobWinBannerViewClass alloc] 
								  initMobWinBannerSizeIdentifier:self.nSizeAd
								  integrationKey:@"ben1574leo"];
	if (nil == adBanner)
		return nil;
	
	adBanner.delegate = self;
	adBanner.rootViewController = [self.adViewDelegate viewControllerForPresentingModalView];
	adBanner.adUnitID = [self appId];
	//
	// 腾讯MobWIN提示：开发者可选调用
	//
	adBanner.adGpsMode = [self helperUseGpsMode];
	
	//adBanner.adTextColor = [self helperTextColorToUse];
	//adBanner.adSubtextColor = [self helperSecondaryTextColorToUse];
	//adBanner.adBackgroundColor = [self helperBackgroundColorToUse];

	self.adNetworkView = adBanner;
	//[adBanner startRequest];
	return adBanner;
}

#pragma mark MobWinDelegate methods

// 详解:请求插播广告成功时调用
- (void)bannerViewDidReceived {
	AWLogInfo(@"mobwin bannerViewDidReceived");
	[self.adViewView adapter:self didReceiveAdView:self.adNetworkView];
    self.bWaitAd = NO;
}
 
// 详解:请求插播广告失败时调用
- (void)bannerViewFailToReceived {
	AWLogInfo(@"mobwin bannerViewFailToReceived");
	[self.adViewView adapter:self didFailAd:nil];
    self.bWaitAd = NO;
}

// 详解:将要展示一次插播广告内容前调用
- (void)bannerViewDidPresentScreen {
	AWLogInfo(@"mobwin bannerViewDidPresentScreen");
	[self helperNotifyDelegateOfFullScreenModal];
}

// 详解:插播广告展示完成，结束插播广告后调用
- (void)bannerViewDidDismissScreen {
	AWLogInfo(@"mobwin bannerViewDidDismissScreen");
	[self helperNotifyDelegateOfFullScreenModalDismissal];
}

@end
