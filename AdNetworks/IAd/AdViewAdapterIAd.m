/*
 
 Copyright 2010 www.adview.cn. All rights reserved.
 
 */

#import "AdViewAdapterIAd.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewViewImpl.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"

#if	1	//defined(__IPHONE_4_2)
NSString * const ADBannerContentSizeIdentifier320x50_sim = @"ADBannerContentSizePortrait";
NSString * const ADBannerContentSizeIdentifier480x32_sim = @"ADBannerContentSizeLandscape";
#else
NSString * const ADBannerContentSizeIdentifier320x50_sim = @"ADBannerContentSize320x50";
NSString * const ADBannerContentSizeIdentifier480x32_sim = @"ADBannerContentSize480x32";
#endif


@implementation AdViewAdapterIAd

+ (AdViewAdNetworkType)networkType {
	return AdViewAdNetworkTypeIAd;
}

+ (void)load {
	if(NSClassFromString(@"ADBannerView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	Class adBannerViewClass = NSClassFromString (@"ADBannerView");
	
	if (nil == adBannerViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no iad lib support, can not create.");
		return;
	}
	
	ADBannerView *iAdView = [[adBannerViewClass alloc] initWithFrame:CGRectZero];
	if (nil == iAdView) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}	
	
	iAdView.requiredContentSizeIdentifiers = [NSSet setWithObjects:
                                            ADBannerContentSizeIdentifier320x50_sim,
                                            ADBannerContentSizeIdentifier480x32_sim,
                                            nil];
	
  BOOL isLandscape = [self helperIsLandscape];

  if (isLandscape) {
    iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier480x32_sim;
  }
  else {
    iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50_sim;
  }
	[iAdView setDelegate:self];

	self.adNetworkView = iAdView;
  [iAdView release];
}

- (void)stopBeingDelegate {
  ADBannerView *iAdView = (ADBannerView *)self.adNetworkView;
	AWLogInfo(@"iad stop being delegate");
  if (iAdView != nil) {
    iAdView.delegate = nil;
	  //[iAdView removeFromSuperview];
	  //self.adNetworkView = nil;
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
				self.nSizeAd = 0;
				break;
			case AdviewBannerSize_300x250:
				self.nSizeAd = 0;
				break;
			case AdviewBannerSize_480x60:
				self.nSizeAd = 0;
				break;
			case AdviewBannerSize_728x90:
				self.nSizeAd = 0;
				break;
			default:
				break;
		}
	} else if (isIPad) {
		self.nSizeAd = 0;
	} else {
		self.nSizeAd = 0;
	}
}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation {
  ADBannerView *iAdView = (ADBannerView *)self.adNetworkView;
  if (iAdView == nil) return;
  if (UIInterfaceOrientationIsLandscape(orientation)) {
    iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier480x32_sim;
  }
  else {
    iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50_sim;
  }
  // ADBanner positions itself in the center of the super view, which we do not
  // want, since we rely on publishers to resize the container view.
  // position back to 0,0
  CGRect newFrame = iAdView.frame;
  newFrame.origin.x = newFrame.origin.y = 0;
  iAdView.frame = newFrame;
}

- (BOOL)isBannerAnimationOK:(AWBannerAnimationType)animType {
  if (animType == AWBannerAnimationTypeFadeIn) {
    return NO;
  }
  return YES;
}

- (void)dealloc {
	[super dealloc];
}

#pragma mark IAdDelegate methods

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
  // ADBanner positions itself in the center of the super view, which we do not
  // want, since we rely on publishers to resize the container view.
  // position back to 0,0
  CGRect newFrame = banner.frame;
  newFrame.origin.x = newFrame.origin.y = 0;
  banner.frame = newFrame;

	[adViewView adapter:self didReceiveAdView:banner];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
	[adViewView adapter:self didFailAd:error];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
	[self helperNotifyDelegateOfFullScreenModal];
	return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
	[self helperNotifyDelegateOfFullScreenModalDismissal];
}

@end
