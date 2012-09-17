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
#import "AdViewAdapterVpon.h"
#import "AdOnPlatform.h"

@interface AdViewAdapterVpon ()
- (NSString *) adonLicenseKey;
- (BOOL)isTestMode;
@end


@implementation AdViewAdapterVpon

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeVPON;
}

+ (void)load {
	if(NSClassFromString(@"VponAdOn") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];	
	}
}

- (void)getAd {
	Class vponAdOnClass = NSClassFromString (@"VponAdOn");
	
	if (nil == vponAdOnClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no vpon lib, can not create.");
		return;
	}
	
	[self updateSizeParameter];
	
	[vponAdOnClass initializationPlatform:CN];
	AWLogInfo(@"Vpon version:%@",[vponAdOnClass getVersionVpon]);	
	
	if ([self isTestMode]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"VPON_UDID" object:nil];
	}
    
    [[vponAdOnClass sharedInstance] setIsVponLogo:YES];
	[[vponAdOnClass sharedInstance] setLocationOnOff:[self helperUseGpsMode]];

    
    UIViewController *vpon = [[vponAdOnClass sharedInstance] adwhirlRequestDelegate:self 
																  licenseKey:[self adonLicenseKey] 
																		size:self.sSizeAd];
	if (nil == vpon) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}
	
	UIView *adView = vpon.view;
	
	adView.backgroundColor = [self helperBackgroundColorToUse];
	
	//[adViewView adapter:self shouldAddAdView:adView];
	self.adNetworkView = adView;
}

- (void)stopBeingDelegate {
  UIView *adView = (UIView *)self.adNetworkView;
	AWLogInfo(@"--Vpon stopBeingDelegate--");
  if (adView != nil) {
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
				self.sSizeAd = ADON_SIZE_320x48;
				break;
			case AdviewBannerSize_300x250:
				self.sSizeAd = ADON_SIZE_320X270;
				break;
			case AdviewBannerSize_480x60:
				self.sSizeAd = ADON_SIZE_480x72;
				break;
			case AdviewBannerSize_728x90:
				self.sSizeAd = ADON_SIZE_700x108;
				break;
			default:
				break;
		}
	} else if (isIPad) {
		self.sSizeAd = ADON_SIZE_700x108;
	} else {
		self.sSizeAd = ADON_SIZE_320x48;
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

//return your adon Licenese Key
- (NSString *) adonLicenseKey {
	NSString *apID;
	if ([adViewDelegate respondsToSelector:@selector(VponAdOnApIDString)]) {
		apID = [adViewDelegate VponAdOnApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
	return apID;
	
	//return @"f2d0d34b319804690131a50de5900099";//@"fixme";
	
}

#pragma mark Delegate

#pragma mark 回傳點擊點廣是否有效
- (void)onClickAd:(UIViewController *)bannerView withValid:(BOOL)isValid withLicenseKey:(NSString *)adLicenseKey
{
	AWLogInfo(@"vpon click:%d", isValid);
}

#pragma mark 回傳Vpon廣告抓取成功
- (void)onRecevieAd:(UIViewController *)bannerView withLicenseKey:(NSString *)licenseKey
{
	AWLogInfo(@"did receive an ad from vpon");
    [adViewView adapter:self didReceiveAdView:bannerView.view];	
}

#pragma mark 回傳Vpon廣告抓取失敗
- (void)onFailedToRecevieAd:(UIViewController *)bannerView withLicenseKey:(NSString *)licenseKey
{
	AWLogInfo(@"adview failed from vpon");
	[adViewView adapter:self didFailAd:nil];		
}

@end
