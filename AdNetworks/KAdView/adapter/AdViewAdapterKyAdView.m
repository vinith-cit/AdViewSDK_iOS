/*
 adview app recommend
*/

#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewDelegateProtocol.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "AdViewAdapterKyAdView.h"
#import "AdOnPlatform.h"
#import "AdViewExtraManager.h"

@interface AdViewAdapterKyAdView ()
- (BOOL)isTestMode;
@end


@implementation AdViewAdapterKyAdView

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeAdviewApp;
}

+ (void)load {
	if(NSClassFromString(@"KOpenAPIAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];	
	}
}

- (void)getAd {
	Class KyAdViewAdOnClass = NSClassFromString (@"KOpenAPIAdView");
	
	if (nil == KyAdViewAdOnClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no KyAdView lib, can not create.");
		return;
	}
	
	[self updateSizeParameter];
	
	KOpenAPIAdView *adView = [KyAdViewAdOnClass requestOfSize: self.sSizeAd withDelegate:self
												   withAdType:KOPENAPIADTYPE_DEFAULT];
	if (nil == adView) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}
	adView.location = [[AdViewExtraManager sharedManager] getLocation];
	
	//[adViewView adapter:self shouldAddAdView:adView];
	self.adNetworkView = adView;
	[adView resumeRequestAd];
}

- (void)stopBeingDelegate {
  KOpenAPIAdView *adView = (KOpenAPIAdView *)self.adNetworkView;
	AWLogInfo(@"--KyApp stopBeingDelegate--");
  if (adView != nil) {
	  [adView pauseRequestAd];
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
				self.sSizeAd = KOPENAPIADVIEW_SIZE_320x48;
				break;
			case AdviewBannerSize_300x250:
				self.sSizeAd = KOPENAPIADVIEW_SIZE_300x250;
				break;
			case AdviewBannerSize_480x60:
				self.sSizeAd = KOPENAPIADVIEW_SIZE_480x60;
				break;
			case AdviewBannerSize_728x90:
				self.sSizeAd = KOPENAPIADVIEW_SIZE_728x90;
				break;
			default:
				break;
		}
	} else if (isIPad) {
		self.sSizeAd = KOPENAPIADVIEW_SIZE_728x90;
	} else {
		self.sSizeAd = KOPENAPIADVIEW_SIZE_320x48;
	}
}

- (void)dealloc {
  [super dealloc];
}

- (BOOL)isTestMode {
	if (nil != adViewDelegate
		&& [adViewDelegate respondsToSelector:@selector(adViewTestMode)]) {
		return [adViewDelegate adViewTestMode];
	}
	return NO;
}

- (NSString *) appId {
	NSString *apID;

	apID = [adViewDelegate adViewApplicationKey];

	return apID;
}

- (NSString*) kAdViewHost {
	return self.networkConfig.pubId2;
}

-(int)	autoRefreshInterval {
	return -1;
}

-(BOOL) testMode {
	return NO;//[self isTestMode];
}

-(BOOL) logMode {
	if (nil != adViewDelegate
		&& [adViewDelegate respondsToSelector:@selector(adViewLogMode)]) {
		return [adViewDelegate adViewLogMode];
	}
	return NO;
}

#pragma mark Delegate

-(UIColor*) adTextColor {
	return [self helperTextColorToUse];
}

-(UIColor*) adBackgroundColor {
	return [self helperBackgroundColorToUse];
}

-(int)gradientBgType {
	if (nil != adViewDelegate
		&& [adViewDelegate respondsToSelector:@selector(adViewAppAdBackgroundGradientType)]) {
		return [adViewDelegate adViewAppAdBackgroundGradientType];
	}
	return 0;
}

-(void) didReceivedAd: (KOpenAPIAdView*) adView {
	AWLogInfo(@"did receive an ad from KyAdView");
    [adViewView adapter:self didReceiveAdView:adView];	
}

-(void)didFailToReceiveAd:(KOpenAPIAdView*)adView Error:(NSError*)error {
	AWLogInfo(@"adview failed from KyAdView:%@", [error localizedDescription]);
	[adViewView adapter:self didFailAd:nil];		
}

-(UIViewController*)viewControllerForShowModal {
	return [adViewDelegate viewControllerForPresentingModalView];
}

- (void)adViewWillPresentScreen:(KOpenAPIAdView *)adView {
	[self helperNotifyDelegateOfFullScreenModal];	
}

- (void)adViewDidDismissScreen:(KOpenAPIAdView *)adView {
	[self helperNotifyDelegateOfFullScreenModalDismissal];
}

@end
