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
#import "AdViewAdapterAdFracta.h"
#import "FtadManager.h"
#import "FtadBannerView.h"
#import "FtadSdk.h"

#import "AdViewExtraManager.h"

#define ADFRACTA_VIEW_CLASS_NAME @"FtadBannerView"

@implementation AdViewAdapterAdFracta

@synthesize ftAdManager = _ftAdManager;
@synthesize ftAdBanner = _ftAdBanner;

+ (AdViewAdNetworkType) networkType {
    return AdViewAdNetworkTypeAdFracta;
}

+ (void) load
{
    if (NSClassFromString(ADFRACTA_VIEW_CLASS_NAME)){
        //AWLogInfo(@"AdView: Found Fracta AdNetwork");
        [[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
    }
}

- (void) getAd
{
	NSString *appID = self.networkConfig.pubId;
	if (nil == appID) appID = @"";
    AWLogInfo(@"AdFracta: application id: %@", appID);
    
    UIViewController* controller = [self.adViewDelegate viewControllerForPresentingModalView];

    Class adfracta_view_class = NSClassFromString(ADFRACTA_VIEW_CLASS_NAME);
	if (nil == adfracta_view_class) {
		[self.adViewView adapter:self didFailAd:nil];
		return;
	}
	
	Class FtadSdk_Cls = NSClassFromString(@"FtadSdk");
	
	[FtadSdk_Cls initSdkConfig:appID];//@"560";
	[FtadSdk_Cls setRootViewController:controller];
	[FtadSdk_Cls setNeedLocation:[self helperUseGpsMode]];
	if ([self helperUseGpsMode] && nil != [AdViewExtraManager sharedManager]) {
		CLLocation *loc = [[AdViewExtraManager sharedManager] getLocation];
		if (nil != loc)
			[FtadSdk_Cls updateLocationWithLatitudeAndLongitude:loc.coordinate.latitude
								   longitude:loc.coordinate.longitude];
	}	
	
	[self updateSizeParameter];
    CGRect r = CGRectMake(0.0f, 0.0f, self.sSizeAd.width, self.sSizeAd.height);
    FtadBannerView* adfracta_view = [adfracta_view_class newFtadBannerViewWithPointAndSize:CGPointMake(0, 0) 
																			  size:self.sSizeAd 
																		adIdentify:@"adview_banner"
																		  delegate:self];
	
	if (nil == adfracta_view) {
		[self.adViewView adapter:self didFailAd:nil];
		return;
	}
	
	adfracta_view.isClose = NO;
    adfracta_view.rootViewController_ = controller;
	
	UIView *dummyView = [[UIView alloc] initWithFrame:r];
	[dummyView addSubview:adfracta_view];
	
    self.adNetworkView = dummyView;
	[dummyView release];
	self.ftAdBanner = adfracta_view;
	
	Class FtadManager_Class = NSClassFromString(@"FtadManager");
	self.ftAdManager = [[FtadManager_Class alloc] init];
	//[self.ftAdManager setPublisherid:appID];
	
	self.ftAdManager.timeInterval = 0;
	[self.ftAdManager addFtadBannerView:adfracta_view];
	[self.ftAdManager start];
	[adfracta_view release];
}

- (void) stopBeingDelegate
{
	FtadBannerView *adFtView = self.ftAdBanner;
	AWLogInfo(@"--AdFracta stopBeingDelegate--");
	if (nil != adFtView) {
		[adFtView performSelector:@selector(setRootViewController_:) withObject:nil];
		[self.ftAdManager stop];
		[self.ftAdManager removeFtadBannerView:adFtView];
		self.ftAdManager = nil;
	}
	self.ftAdBanner = nil;
	self.adNetworkView = nil;
}

- (void)updateSizeParameter {
	BOOL isIPad = [AdViewAdNetworkAdapter helperIsIpad];
	
	AdviewBannerSize	sizeId = AdviewBannerSize_Auto;
	if ([self.adViewDelegate respondsToSelector:@selector(PreferBannerSize)]) {
		sizeId = [self.adViewDelegate PreferBannerSize];
	}
	
	if (sizeId > AdviewBannerSize_Auto) {
		switch (sizeId) {
			case AdviewBannerSize_320x50:
				self.nSizeAd = 0;
				self.sSizeAd = AD_SIZE_320x48;
				break;
			case AdviewBannerSize_300x250:
				self.nSizeAd = 0;
				self.sSizeAd = AD_SIZE_320x270;
				break;
			case AdviewBannerSize_480x60:
				self.nSizeAd = 0;
				self.sSizeAd = AD_SIZE_488x80;
				break;
			case AdviewBannerSize_728x90:
				self.nSizeAd = 0;
				self.sSizeAd = AD_SIZE_768x116;
				break;
			default:
				break;
		}
	} else if (isIPad) {
		self.nSizeAd = 0;
		self.sSizeAd = AD_SIZE_768x116;
	} else {
		self.nSizeAd = 0;
		self.sSizeAd = AD_SIZE_320x48;
	}
}

- (void) dealloc
{
    [super dealloc];
}

#pragma mark FtadStatusDelegate

//
//
-(void)didFtadReceiveAdFail:(NSString*)adIdentify
{
	AWLogInfo(@"didFtadReceiveAdFail:%@", adIdentify);
	[self.adViewView adapter:self didFailAd:nil];	
}

//
//
-(void)didFtadReceiveAdSuccess:(NSString*)adIdentify
{
	[self.adViewView adapter:self didReceiveAdView:self.adNetworkView];	
}

//
//
-(void)didFtadRefreshAd:(NSString*)adIdentify
{
}

//
//
-(void)didFtadClick:(NSString*)adIdentify
{
}

//
//
-(void)willFtadViewClosed:(NSString*)adIdentify
{
}

//
//
-(void)willFtadFullScreenShow:(NSString*)adIdentify
{
	[self helperNotifyDelegateOfFullScreenModal];
}

//
//
-(void)didFtadFullScreenShow:(NSString*)adIdentify;
{
}

//
//
-(void)willFtadFullScreenClose:(NSString*)adIdentify
{
}

//
//
-(void)didFtadFullScreenClose:(NSString*)adIdentify
{
	[self helperNotifyDelegateOfFullScreenModalDismissal];
}


@end
