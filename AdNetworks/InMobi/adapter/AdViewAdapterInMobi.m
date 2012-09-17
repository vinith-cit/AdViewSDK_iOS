/*
 
 Copyright 2010 www.adview.cn. All rights reserved.
 
 */

#import "AdViewAdapterInMobi.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewViewImpl.h"
#import "IMAdView.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"

#import "SingletonAdapterBase.h"
#import "AdViewExtraManager.h"

@interface AdViewAdapterInMobiImpl : SingletonAdapterBase <IMAdDelegate> 

- (NSString *)appId;

@end

static AdViewAdapterInMobiImpl *gAdInMobiImpl = nil;

@implementation AdViewAdapterInMobi

+ (AdViewAdNetworkType)networkType {
	return AdViewAdNetworkTypeInMobi;
}

+ (void)load {
	if(NSClassFromString(@"IMAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {	
	Class IMAdViewClass = NSClassFromString (@"IMAdView");
	Class IMAdRequestClass = NSClassFromString (@"IMAdRequest");	
	if (nil == IMAdViewClass || nil == IMAdRequestClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no inmobi lib, can not create.");
		return;
	}
	
	if (nil == gAdInMobiImpl) gAdInMobiImpl = [[AdViewAdapterInMobiImpl alloc] init];
	[gAdInMobiImpl setAdapterValue:YES ByAdapter:self];
	IMAdView *inmobiAdView = (IMAdView*)[gAdInMobiImpl getIdelAdView];
	if (nil == inmobiAdView) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"fail to getAd of InMobi");
		return;
	}
	
    IMAdRequest *request = [IMAdRequestClass request];
	inmobiAdView.refreshInterval = REFRESH_INTERVAL_OFF;
	
    // additional targeting parameters. these are optional
#if 0
    request.gender = G_M;
    request.education = Edu_BachelorsDegree;
    request.interests = @"sports,cars,bikes";
    request.postalCode = @"12345";
    request.location = [[[CLLocation alloc] initWithLatitude:12.88 longitude:12.11] autorelease];
#endif
	
	if ([AdViewExtraManager sharedManager]) {
		request.location = [[AdViewExtraManager sharedManager] getLocation];
	}
	
    //Make sure to set testMode to NO before submitting to App Store.
    request.testMode = [gAdInMobiImpl isTestMode];
	request.paramsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"c_adview", @"tp", nil];
    inmobiAdView.imAdRequest = request;
	self.adNetworkView = inmobiAdView;
	[inmobiAdView loadIMAdRequest:request];
	[inmobiAdView release];
	
	[self setupDummyHackTimer:28];
}

- (void)stopBeingDelegate {
	IMAdView *adView = (IMAdView*)self.adNetworkView;
	AWLogInfo(@"--InMobi stopBeingDelegate--");
	[self cleanupDummyHackTimer];	
	if (nil != adView) {
		[gAdInMobiImpl setAdapterValue:NO ByAdapter:self];
		adView.delegate = nil;
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
				self.nSizeAd = IM_UNIT_320x50;
				self.rSizeAd = CGRectMake(0, 0, 320, 50);
				break;
			case AdviewBannerSize_300x250:
				self.nSizeAd = IM_UNIT_300x250;
				self.rSizeAd = CGRectMake(0, 0, 300, 250);
				break;
			case AdviewBannerSize_480x60:
				self.nSizeAd = IM_UNIT_468x60;
				self.rSizeAd = CGRectMake(0, 0, 468, 60);
				break;
			case AdviewBannerSize_728x90:
				self.nSizeAd = IM_UNIT_728x90;
				self.rSizeAd = CGRectMake(0, 0, 728, 90);
				break;
			default:
				break;
		}
	} else if (isIPad) {
		self.nSizeAd = IM_UNIT_728x90;
		self.rSizeAd = CGRectMake(0, 0, 728, 90);
	} else {
		self.nSizeAd = IM_UNIT_320x50;
		self.rSizeAd = CGRectMake(0, 0, 320, 50);
	}
}

- (void)dealloc {
	[super dealloc];
}

@end

@implementation AdViewAdapterInMobiImpl

- (UIView*)createAdView {
	Class IMAdViewClass = NSClassFromString (@"IMAdView");	
	if (nil == IMAdViewClass) {
		return nil;
	}
	
	[mAdapter updateSizeParameter];
	IMAdView *inmobiAdView = [[IMAdViewClass alloc] initWithFrame:mAdapter.rSizeAd
														  imAppId:[self appId]
														 imAdUnit:mAdapter.nSizeAd 
											   rootViewController:[mAdapter.adViewDelegate viewControllerForPresentingModalView]];
    inmobiAdView.delegate = self;
	return inmobiAdView;
}

#pragma mark InMobiAdDelegate methods

- (NSString *)appId {
	if ([mAdapter.adViewDelegate respondsToSelector:@selector(inmobiApIDString)]) {
		return [mAdapter.adViewDelegate inmobiApIDString];
	}
	return mAdapter.networkConfig.pubId;
	//@"4028cbff379738bf01383102f0e8220c"
}

- (void)adViewDidFinishRequest:(IMAdView *)view {
	AWLogInfo(@"<<<<<ad request completed>>>>>");
	if (![self isAdViewValid:view]) return;
	
	if (nil == mAdapter) return;
	
	[mAdapter cleanupDummyHackTimer];
	[mAdapter.adViewView adapter:mAdapter didReceiveAdView:view];
}

- (void)adView:(IMAdView *)view didFailRequestWithError:(IMAdError *)error {
	AWLogInfo(@"<<<< ad request failed.>>>, error=%@",[error localizedDescription]);
	AWLogInfo(@"error code=%d",[error code]);
	if (![self isAdViewValid:view]) return;
	
	if (nil == mAdapter) return;
	
	[mAdapter cleanupDummyHackTimer];
	[mAdapter.adViewView adapter:mAdapter didFailAd:nil];
}

- (void)adViewDidDismissScreen:(IMAdView *)adView {
    AWLogInfo(@"adViewDidDismissScreen");
	[mAdapter helperNotifyDelegateOfFullScreenModalDismissal];
}

- (void)adViewWillDismissScreen:(IMAdView *)adView {
    AWLogInfo(@"adViewWillDismissScreen");
}

- (void)adViewWillPresentScreen:(IMAdView *)adView {
    AWLogInfo(@"adViewWillPresentScreen");
	[mAdapter helperNotifyDelegateOfFullScreenModal];
}

- (void)adViewWillLeaveApplication:(IMAdView *)adView {
    AWLogInfo(@"adViewWillLeaveApplication");
}

@end
