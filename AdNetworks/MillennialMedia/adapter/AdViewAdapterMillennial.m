/*
 
 Copyright 2010 www.adview.cn. All rights reserved.
 
 */

#import "AdViewAdapterMillennial.h"
#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewDelegateProtocol.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"

#import "AdViewExtraManager.h"
#import "AdviewObjCollector.h"

#define kMillennialAdFrame_Iphone (CGRectMake(0, 0, 320, 53))
#define kMillennialAdFrame_Ipad (CGRectMake(0, 0, 768, 90))

@interface AdViewAdapterMillennial ()

- (CLLocationDegrees)latitude;

- (CLLocationDegrees)longitude;

- (NSInteger)age;

- (NSString *)zipCode;

- (NSString *)sex;

@end


@implementation AdViewAdapterMillennial

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeMillennial;
}

+ (void)load {
	if(NSClassFromString(@"MMAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
  NSString *apID;
  if ([adViewDelegate respondsToSelector:@selector(millennialMediaApIDString)]) {
    apID = [adViewDelegate millennialMediaApIDString];
  }
  else {
    apID = networkConfig.pubId;
  }

  requestData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                 @"adview", @"vendor",
                 nil];
  if ([self respondsToSelector:@selector(zipCode)]) {
    [requestData setValue:[self zipCode] forKey:@"zip"];
  }
  if ([self respondsToSelector:@selector(age)]) {
    [requestData setValue:[NSString stringWithFormat:@"%d",[self age]] forKey:@"age"];
  }
  if ([self respondsToSelector:@selector(sex)]) {
    [requestData setValue:[self sex] forKey:@"sex"];
  }
  if ([self respondsToSelector:@selector(latitude)]) {
    [requestData setValue:[NSString stringWithFormat:@"%lf",[self latitude]] forKey:@"lat"];
  }
  if ([self respondsToSelector:@selector(longitude)]) {
    [requestData setValue:[NSString stringWithFormat:@"%lf",[self longitude]] forKey:@"long"];
  }
  MMAdType adType = MMBannerAdTop;
	Class mmAdViewClass = NSClassFromString (@"MMAdView");
	
	if (nil == mmAdViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no Millennial lib, can not create adviewview.");
		return;
	}
	if ([self helperUseGpsMode] && nil != [AdViewExtraManager sharedManager]) {
		CLLocation *loc = [[AdViewExtraManager sharedManager] getLocation];
		if (nil != loc) [mmAdViewClass updateLocation:loc];
	}
	
  [self updateSizeParameter];
  MMAdView *adView = [mmAdViewClass adWithFrame:self.rSizeAd
                                      type:adType
                                      apid:apID
									delegate:self  // Must be set, CANNOT be nil
									loadAd:YES   // Loads an ad immediately
									 startTimer:NO];
	if (nil == adView) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}	
	
  adView.rootViewController = [adViewDelegate viewControllerForPresentingModalView];
  self.adNetworkView = adView;
  self.bWaitAd = YES;
}

- (void)stopBeingDelegate {
  MMAdView *adView = (MMAdView *)self.adNetworkView;
    AWLogInfo(@"--MillennialMedia stopBeingDelegate--");
  if (adView != nil) {
	  adView.refreshTimerEnabled = NO;
	  adView.delegate = nil;
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
				self.rSizeAd = kMillennialAdFrame_Iphone;
				break;
			case AdviewBannerSize_300x250:
				self.rSizeAd = kMillennialAdFrame_Iphone;
				break;
			case AdviewBannerSize_480x60:
				self.rSizeAd = kMillennialAdFrame_Iphone;
				break;
			case AdviewBannerSize_728x90:
				self.rSizeAd = kMillennialAdFrame_Ipad;
				break;
			default:
				break;
		}
	} else if (isIPad) {
		self.rSizeAd = kMillennialAdFrame_Ipad;
	} else {
		self.rSizeAd = kMillennialAdFrame_Iphone;
	}
}

- (void)dealloc {
  [requestData release];
  [super dealloc];
}

#pragma mark MMAdDelegate methods

- (NSDictionary *)requestData {
  AWLogInfo(@"Sending requestData to MM: %@", requestData);
  return requestData;
}

- (BOOL)testMode {
  if ([adViewDelegate respondsToSelector:@selector(adViewTestMode)])
    return [adViewDelegate adViewTestMode];
  return NO;
}

- (void)adRequestSucceeded:(MMAdView *)adView {
  // millennial ads are slightly taller than default frame, at 53 pixels.
  AWLogInfo(@"adRequestSucceeded from millennial");
  [adViewView adapter:self didReceiveAdView:adNetworkView];
  self.bWaitAd = NO;
}

- (void)adRequestFailed:(MMAdView *)adView {
  AWLogInfo(@"adRequestFailed from millennial");
  [adViewView adapter:self didFailAd:nil];
  self.bWaitAd = NO;
}

- (void)adModalWillAppear {
  [self helperNotifyDelegateOfFullScreenModal];
}

- (void)adModalWasDismissed {
  [self helperNotifyDelegateOfFullScreenModalDismissal];
}

#pragma mark requestData optional methods

- (CLLocationDegrees)latitude {
	if ([self helperUseGpsMode] && nil != [AdViewExtraManager sharedManager]) {
		CLLocation *loc = [[AdViewExtraManager sharedManager] getLocation];
		if (nil != loc) return loc.coordinate.latitude;
	}
	return 0.0;
}

- (CLLocationDegrees)longitude {
	if ([self helperUseGpsMode] && nil != [AdViewExtraManager sharedManager]) {
		CLLocation *loc = [[AdViewExtraManager sharedManager] getLocation];
		if (nil != loc) return loc.coordinate.longitude;
	}	
	return 0.0;
}

- (NSInteger)age {
	return -1;
}

- (NSString *)zipCode {
	return @"";
}

- (NSString *)sex {
	return @"";
}

/*
- (NSInteger)householdIncome {
  return (NSInteger)[adViewDelegate incomeLevel];
}

- (MMEducation)educationLevel {
  return [adViewDelegate millennialMediaEducationLevel];
}

- (MMEthnicity)ethnicity {
  return [adViewDelegate millennialMediaEthnicity];
}
*/

@end
