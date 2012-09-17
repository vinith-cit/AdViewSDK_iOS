/*
 
 Copyright 2010 www.adview.cn. All rights reserved.
 
 */

#import "AdViewViewImpl.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewAdNetworkRegistry.h"
#import "AdViewLog.h"
#import "AdViewView.h"
#import "AdViewAdapterUMAd.h"

#define NEED_IN_REALVIEW	1

#define UMADBANNERVIEW_CLASS_NAME @"UMAdBannerView"
#define UMADMANAGER_CLASS_NAME @"UMAdManager"

@implementation AdViewAdapterUMAd
@synthesize umadClientIdString = _umadClientIdString;
@synthesize umadSlotIdString = _umadSlotIdString;

+ (AdViewAdNetworkType) networkType {
    return AdViewAdNetworkTypeUMAd;
}

+ (void) load
{
    if (NSClassFromString(UMADBANNERVIEW_CLASS_NAME) && NSClassFromString(UMADMANAGER_CLASS_NAME)) {
        //AWLogInfo(@"Found UMAD AdNetwork");
        [[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
    }
}

- (void) getAd
{
    self.umadSlotIdString = [self.networkConfig pubId2];
    self.umadClientIdString = [self.networkConfig pubId];
    AWLogInfo(@"UMAd: client id: %@", self.umadClientIdString);
    AWLogInfo(@"UMAd: slot id: %@", self.umadSlotIdString);
    
    Class umad_manager_class = NSClassFromString(UMADMANAGER_CLASS_NAME);
	if (nil == umad_manager_class) {
		[self.adViewView adapter:self didFailAd:nil];
		return;
	}	
    [umad_manager_class performSelector: @selector(setAppDelegate:) withObject: self];
    [umad_manager_class performSelector: @selector(appLaunched)];
    
    Class umad_bannerview_class = NSClassFromString(UMADBANNERVIEW_CLASS_NAME);
    UIView* umad_view = [[umad_bannerview_class alloc] init];
	if (nil == umad_view) {
		[self.adViewView adapter:self didFailAd:nil];
		return;
	}
    [umad_view performSelector:@selector(setProperty:slotid:)
                    withObject:[self.adViewDelegate viewControllerForPresentingModalView]
                    withObject:self.umadSlotIdString];
    [umad_view performSelector:@selector(setDelegate:) withObject:self];
    
	[self updateSizeParameter];
	
    umad_view.frame = self.rSizeAd;
	
#if NEED_IN_REALVIEW
	if ([self.adViewDelegate respondsToSelector:@selector(viewControllerForPresentingModalView)])
	{
		UIViewController *controller = [self.adViewDelegate viewControllerForPresentingModalView];
		if (nil != controller && nil != controller.view)
		{
			[controller.view addSubview:umad_view];
			umad_view.hidden = YES;
		}
	}
#endif
    self.adNetworkView = umad_view;
    [umad_view release];
}

- (void) stopBeingDelegate
{
    UMAdBannerView* umad_view = (UMAdBannerView*)self.adNetworkView;
	if (nil != umad_view) {
		[umad_view setProperty:nil slotid:self.umadSlotIdString];
		[umad_view setDelegate:nil];
		
		[umad_view removeFromSuperview];
		self.adNetworkView = nil;
	}

    Class umad_manager_class = NSClassFromString(UMADMANAGER_CLASS_NAME);
    [umad_manager_class setAppDelegate:nil];
}

- (void)cleanupDummyRetain
{
    UMAdBannerView* umad_view = (UMAdBannerView*)self.adNetworkView;
	if (nil != umad_view) {
		[umad_view setDelegate:nil];
	}
	
    Class umad_manager_class = NSClassFromString(UMADMANAGER_CLASS_NAME);
    [umad_manager_class setAppDelegate:nil];
	
	[super cleanupDummyRetain];
}

- (void)updateSizeParameter {
	BOOL isIPad = [AdViewAdNetworkAdapter helperIsIpad];
	
	AdviewBannerSize	sizeId = AdviewBannerSize_Auto;
	if ([self.adViewDelegate respondsToSelector:@selector(PreferBannerSize)]) {
		sizeId = [self.adViewDelegate PreferBannerSize];
	}
		
#if 1	//to umeng, only 320X50 in iphone, and the other in ipad.
	if (sizeId > AdviewBannerSize_Auto) {
		switch (sizeId) {
			case AdviewBannerSize_320x50:
				self.sSizeAd = [UMAdBannerView bannerSizeofSize320x50];
				break;
			case AdviewBannerSize_300x250:
				self.sSizeAd = [UMAdBannerView bannerSizeofSize320x50];
				break;
			case AdviewBannerSize_480x60:
				self.sSizeAd = [UMAdBannerView bannerSizeofSize480x75];
				break;
			case AdviewBannerSize_728x90:
				self.sSizeAd = [UMAdBannerView bannerSizeofSize480x75];
				break;
			default:
				break;
		}
	} else
#endif
		if (isIPad) {
		self.sSizeAd = [UMAdBannerView bannerSizeofSize480x75];
	} else {
		self.sSizeAd = [UMAdBannerView bannerSizeofSize320x50];
	}
	self.rSizeAd = CGRectMake(0, 0, self.sSizeAd.width, self.sSizeAd.height);
}

- (void) dealloc
{
    self.umadSlotIdString = nil;
    self.umadClientIdString = nil;
	
    [super dealloc];
}

- (NSString*) UMADClientId
{
    return _umadClientIdString;
}

- (void) UMADBannerViewDidLoadAd:(UMAdBannerView *)banner
{
	AWLogInfo(@"UMADBannerViewDidLoadAd");
    [self.adViewView adapter:self didReceiveAdView:banner];
#if NEED_IN_REALVIEW
	banner.hidden = NO;
#endif
}

- (void) UMADBannerView:(UMAdBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    AWLogInfo(@"AdView: UMAd error: %@", [error localizedDescription]);
    [self.adViewView adapter:self didFailAd:nil];
}

- (void) UMADBannerViewActionWillBegin:(UMAdBannerView *)banner
{
    [self helperNotifyDelegateOfFullScreenModal];
}

- (void) UMADBannerViewActionDidFinish:(UMAdBannerView *)banner
{
    [self helperNotifyDelegateOfFullScreenModalDismissal];
}

- (void) UMWebAdWillLoad:(NSString *)slotid
{
	AWLogInfo(@"UMWebAdWillLoad");
}

- (void) UMWebAdDidLoad:(NSString *)slotid
{
    AWLogInfo(@"UMWebAdDidLoad");
}

- (void) UMWebAd:(NSString *)slotid didFailToReceiveAdWithError:(NSError *)error
{
    AWLogInfo(@"UMWebAd: didFailToReceiveAdWithError:");
}

- (void) UMWebAdViewQuitAction:(NSString *)slotid
{
	AWLogInfo(@"UMWebAdViewQuitAction");
    [self helperNotifyDelegateOfFullScreenModalDismissal];
}
@end
