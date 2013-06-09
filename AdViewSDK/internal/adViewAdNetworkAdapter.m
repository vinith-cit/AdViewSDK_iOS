/*

 AdViewAdNetworkAdapter.m

 Copyright 2010 www.adview.cn

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

#import "AdViewAdNetworkAdapter.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkRegistry.h"
#import <QuartzCore/QuartzCore.h>

BOOL isForeignAd(AdViewAdNetworkType type)
{
	switch (type) {
		case AdViewAdNetworkTypeGreystripe:
		case AdViewAdNetworkTypeAdMob:
		case AdViewAdNetworkTypeIAd:
		case AdViewAdNetworkTypeMillennial:
		case AdViewAdNetworkTypeInMobi:
			return YES;
		default:
			return NO;
	}
	return NO;
}

static NSTimeInterval gDummyTimeInterval = 15.0f;

@implementation AdViewAdNetworkAdapter

@synthesize adViewDelegate;
@synthesize adViewView;
@synthesize adViewConfig;
@synthesize networkConfig;
@synthesize adNetworkView;

@synthesize bWaitAd;

@synthesize bGotView = _bGotView;

@synthesize nSizeAd;
@synthesize rSizeAd;
@synthesize sSizeAd;

@synthesize dummyHackTimer;
@synthesize actAdView;

@synthesize nAdWaitFlag, nAdBlockFlag;

- (id)initWithAdViewDelegate:(id<AdViewDelegate>)delegate
                         view:(AdViewView *)view
                       config:(AdViewConfig *)config
                networkConfig:(AdViewAdNetworkConfig *)netConf {
  self = [super init];
  if (self != nil) {
    self.adViewDelegate = delegate;
    self.adViewView = view;
    self.adViewConfig = config;
    self.networkConfig = netConf;
  }
  return self;
}

- (void)getAd {
  AWLogCrit(@"Subclass of AdViewAdNetworkAdapter must implement -getAd.");
  [self doesNotRecognizeSelector:_cmd];
}

- (void)stopBeingDelegate {
  AWLogCrit(@"Subclass of AdViewAdNetworkAdapter must implement -stopBeingDelegate.");
  [self doesNotRecognizeSelector:_cmd];
}

- (BOOL)shouldSendExMetric {
  return YES;
}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation {
  // do nothing by default. Subclasses implement specific handling.
  AWLogInfo(@"rotate to orientation %d called for adapter %@",
             orientation, NSStringFromClass([self class]));
}

- (BOOL)isBannerAnimationOK:(AWBannerAnimationType)animType {
  return YES;
}

- (void) setupDummyHackTimer:(NSTimeInterval)interval
{
	if (interval < 5) interval = 5;
	
    self.dummyHackTimer = [NSTimer scheduledTimerWithTimeInterval: interval 
                                                           target:self 
														 selector:@selector(dummyHackTimerHandler) userInfo:nil 
                                                          repeats:NO];
}

- (void) setupDefaultDummyHackTimer 
{
	[self setupDummyHackTimer:gDummyTimeInterval];
}

- (void) cleanupDummyHackTimer
{
	if (nil != self.dummyHackTimer)
		[self.dummyHackTimer invalidate];
    self.dummyHackTimer = nil;
}

- (void) dummyHackTimerHandler
{
    self.dummyHackTimer = nil;
    [adViewView adapter:self didFailAd:nil];
}

+ (void) setDummyHackTimeInterval:(int)interval 
{
	if (interval < 5) interval = 5;
	
	gDummyTimeInterval = interval;
}

- (void) cleanupDummyRetain {
	[self cleanupDummyHackTimer];		//this timer will retain self.
}

- (BOOL) canClearDelegate {      //can set adViewView and adViewDelegate as nil.
    return (AdViewAdNetworkBlockFlag_None == self.nAdBlockFlag);
}

//can being delegate even more than one instances being delegate.
- (BOOL) canMultiBeingDelegate
{
    return YES;
}

- (void)dealloc {
  [self stopBeingDelegate];
  adViewDelegate = nil;
  adViewView = nil;
  [adViewConfig release], adViewConfig = nil;
  [networkConfig release], networkConfig = nil;
  [adNetworkView release], adNetworkView = nil;
  [super dealloc];
}

#pragma mark util method for adapter
- (void)updateSizeParameter {
	self.nSizeAd = 0;
	self.rSizeAd = CGRectMake(0, 0, 320, 50);
    self.sSizeAd = CGSizeMake(320, 50);
}

//get index of size in size parameter array.
- (int)getSizeIndex {
	BOOL isIPad = [AdViewAdNetworkAdapter helperIsIpad];
	int	nSizeId = AdviewBannerSize_Auto;
	if ([adViewDelegate respondsToSelector:@selector(PreferBannerSize)]) {
		nSizeId = [adViewDelegate PreferBannerSize];
	}
    if (isIPad && AdviewBannerSize_Auto == nSizeId) ++nSizeId;
    return nSizeId;
}

- (void)setSizeParameter:(int*)flags size:(CGSize*)sizes {
	int nSizeId = [self getSizeIndex];
    
    if (nil != flags) self.nSizeAd = flags[nSizeId];
    if (nil != sizes) self.sSizeAd = sizes[nSizeId];
    self.rSizeAd = CGRectMake(0,0,self.sSizeAd.width,self.sSizeAd.height);
}

- (void)setSizeParameter:(int*)flags rect:(CGRect*)rects {
	int nSizeId = [self getSizeIndex];
    
    if (nil != flags) self.nSizeAd = flags[nSizeId];
    if (nil != rects) self.rSizeAd = rects[nSizeId];
    self.sSizeAd = self.rSizeAd.size;
}

/**
 * Get image of act ad view, add to show, and remove act ad view.
 */
- (void)getImageOfActAdViewForRemove {
    if (nil == self.actAdView) return;

    UIGraphicsBeginImageContext(self.actAdView.bounds.size);
    [self.actAdView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIImageView *iv = [[UIImageView alloc] initWithImage:viewImage];
    [self.adNetworkView addSubview:iv];
    [iv release];
    [self.actAdView removeFromSuperview];
}

/**
 * Added act ad view by a contain view as adNetWorkView.
 */
- (void)addActAdViewInContain:(UIView*)actView rect:(CGRect)rect
{
    [actView setFrame:rect];
    UIView *view1 = [[UIView alloc] initWithFrame:rect];
    [view1 addSubview:actView];
	self.adNetworkView = view1;
    self.actAdView = actView;
    [view1 release];
}

@end
