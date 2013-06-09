/*
 
 SimpleViewController.m
 
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

#import "AdViewSDK_SampleAppDelegate.h"
#import "SimpleViewController.h"
#import "AdViewView.h"
#import "SampleConstants.h"
#import "ModalViewController.h"
#import "AdViewLog.h"

#define SIMPVIEW_BUTTON_1_TAG 607701
#define SIMPVIEW_BUTTON_2_TAG 607702
#define SIMPVIEW_BUTTON_3_TAG 607703
#define SIMPVIEW_BUTTON_4_TAG 607704
#define SIMPVIEW_BUTTON_5_TAG 607705
#define SIMPVIEW_SWITCH_1_TAG 706613
#define SIMPVIEW_LABEL_1_TAG 7066130

#define SIMPVIEW_SWITCH_2_TAG 706614
#define SIMPVIEW_LABEL_2_TAG 7066140

#define SIMPVIEW_BUTTON_1_OFFSET 46
#define SIMPVIEW_BUTTON_2_OFFSET 46
#define SIMPVIEW_BUTTON_3_OFFSET 66
#define SIMPVIEW_BUTTON_4_OFFSET 86
#define SIMPVIEW_BUTTON_5_OFFSET 106
#define SIMPVIEW_SWITCH_1_OFFSET 69
#define SIMPVIEW_LABEL_1_OFFSET 43
#define SIMPVIEW_LABEL_1_OFFSETX 60
#define SIMPVIEW_SWITCH_2_OFFSET 89
#define SIMPVIEW_LABEL_2_OFFSET 63
#define SIMPVIEW_LABEL_2_OFFSETX 80

#define SIMPVIEW_LABEL_OFFSET 94
#define SIMPVIEW_LABEL_HDIFF 45

static BOOL    gSimpTestMode = NO;
static int     gSimpAdSize = AdviewBannerSize_Auto;

static int     gInView = 0;

@implementation SimpleViewController

@synthesize adView;

- (id)init {
    BOOL isIpad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
	if (self = [super initWithNibName:isIpad?@"SimpleViewController_iPad":@"SimpleViewController"
                               bundle:nil]) {
        currLayoutOrientation = UIInterfaceOrientationPortrait; // nib file defines a portrait view
        self.title = @"Simple View";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    ++gInView;
    
    UISwitch *switch2 = (UISwitch *)[self.view viewWithTag:SIMPVIEW_SWITCH_2_TAG];
    switch2.on = gSimpTestMode;
    [self performSelector:@selector(showAdSizeLabel)];
    
    self.adView = [AdViewView requestAdViewViewWithDelegate:self];
    self.adView.autoresizingMask =
    UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:self.adView];
    
    if (getenv("ADVIEW_FAKE_DARTS")) {
        // To make ad network selection deterministic
        const char *dartcstr = getenv("ADVIEW_FAKE_DARTS");
        NSArray *rawdarts = [[NSString stringWithUTF8String:dartcstr]
                             componentsSeparatedByString:@" "];
        NSMutableArray *darts
        = [[NSMutableArray alloc] initWithCapacity:[rawdarts count]];
        for (NSString *dartstr in rawdarts) {
            if ([dartstr length] == 0) {
                continue;
            }
            [darts addObject:[NSNumber numberWithDouble:[dartstr doubleValue]]];
        }
        self.adView.testDarts = darts;
        [darts release];
    }
    
    UIDevice *device = [UIDevice currentDevice];
    if ([device respondsToSelector:@selector(isMultitaskingSupported)] &&
        [device isMultitaskingSupported]) {
#ifdef __IPHONE_4_0
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(enterForeground:)
         name:UIApplicationWillEnterForegroundNotification
         object:nil];
#endif
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self adjustLayoutToOrientation:self.interfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.adView rotateToOrientation:toInterfaceOrientation];
    [self adjustAdSize];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)io
                                         duration:(NSTimeInterval)duration {
    [self adjustLayoutToOrientation:io];
}

- (void)adjustLayoutToOrientation:(UIInterfaceOrientation)newOrientation {
    UIView *button1 = [self.view viewWithTag:SIMPVIEW_BUTTON_1_TAG];
    UIView *button2 = [self.view viewWithTag:SIMPVIEW_BUTTON_2_TAG];
    UIView *button3 = [self.view viewWithTag:SIMPVIEW_BUTTON_3_TAG];
    UIView *button4 = [self.view viewWithTag:SIMPVIEW_BUTTON_4_TAG];
    UIView *button5 = [self.view viewWithTag:SIMPVIEW_BUTTON_5_TAG];
    UIView *switch1 = [self.view viewWithTag:SIMPVIEW_SWITCH_1_TAG];
    UIView *label1 = [self.view viewWithTag:SIMPVIEW_LABEL_1_TAG];
    UIView *switch2 = [self.view viewWithTag:SIMPVIEW_SWITCH_2_TAG];
    UIView *label2 = [self.view viewWithTag:SIMPVIEW_LABEL_2_TAG];
    assert(button1 != nil);
    assert(button2 != nil);
    assert(button3 != nil);
    assert(button4 != nil);
    assert(button5 != nil);
    assert(switch1 != nil);
    assert(label1 != nil);
    assert(switch2 != nil);
    assert(label2 != nil);
    if (UIInterfaceOrientationIsPortrait(currLayoutOrientation)
        && UIInterfaceOrientationIsLandscape(newOrientation)) {
        CGPoint newCenter = button1.center;
        newCenter.y -= SIMPVIEW_BUTTON_1_OFFSET;
        button1.center = newCenter;
        newCenter = button2.center;
        newCenter.y -= SIMPVIEW_BUTTON_2_OFFSET;
        button2.center = newCenter;
        newCenter = button3.center;
        newCenter.y -= SIMPVIEW_BUTTON_3_OFFSET;
        button3.center = newCenter;
        newCenter = button4.center;
        newCenter.y -= SIMPVIEW_BUTTON_4_OFFSET;
        button4.center = newCenter;
        newCenter = button5.center;
        newCenter.y -= SIMPVIEW_BUTTON_5_OFFSET;
        button5.center = newCenter;
        
        newCenter = switch1.center;
        newCenter.y -= SIMPVIEW_SWITCH_1_OFFSET;
        switch1.center = newCenter;
        newCenter = label1.center;
        newCenter.y -= SIMPVIEW_LABEL_1_OFFSET;
        newCenter.x += SIMPVIEW_LABEL_1_OFFSETX;
        label1.center = newCenter;
        
        newCenter = switch2.center;
        newCenter.y -= SIMPVIEW_SWITCH_2_OFFSET;
        switch2.center = newCenter;
        newCenter = label2.center;
        newCenter.y -= SIMPVIEW_LABEL_2_OFFSET;
        newCenter.x += SIMPVIEW_LABEL_2_OFFSETX;
        label2.center = newCenter;
        
        CGRect newFrame = self.label.frame;
        newFrame.size.height -= 45;
        newFrame.origin.y -= SIMPVIEW_LABEL_OFFSET;
        self.label.frame = newFrame;
    }
    else if (UIInterfaceOrientationIsLandscape(currLayoutOrientation)
             && UIInterfaceOrientationIsPortrait(newOrientation)) {
        CGPoint newCenter = button1.center;
        newCenter.y += SIMPVIEW_BUTTON_1_OFFSET;
        button1.center = newCenter;
        newCenter = button2.center;
        newCenter.y += SIMPVIEW_BUTTON_2_OFFSET;
        button2.center = newCenter;
        newCenter = button3.center;
        newCenter.y += SIMPVIEW_BUTTON_3_OFFSET;
        button3.center = newCenter;
        newCenter = button4.center;
        newCenter.y += SIMPVIEW_BUTTON_4_OFFSET;
        button4.center = newCenter;
        newCenter = button5.center;
        newCenter.y += SIMPVIEW_BUTTON_5_OFFSET;
        button5.center = newCenter;
        
        
        newCenter = switch1.center;
        newCenter.y += SIMPVIEW_SWITCH_1_OFFSET;
        switch1.center = newCenter;
        newCenter = label1.center;
        newCenter.y += SIMPVIEW_LABEL_1_OFFSET;
        newCenter.x -= SIMPVIEW_LABEL_1_OFFSETX;
        label1.center = newCenter;
        
        newCenter = switch2.center;
        newCenter.y += SIMPVIEW_SWITCH_2_OFFSET;
        switch2.center = newCenter;
        newCenter = label2.center;
        newCenter.y += SIMPVIEW_LABEL_2_OFFSET;
        newCenter.x -= SIMPVIEW_LABEL_2_OFFSETX;
        label2.center = newCenter;
        
        CGRect newFrame = self.label.frame;
        newFrame.size.height += 45;
        newFrame.origin.y += SIMPVIEW_LABEL_OFFSET;
        self.label.frame = newFrame;
    }
    currLayoutOrientation = newOrientation;
}

- (void)adjustAdSize {
    CGSize adSize = [adView actualAdSize];
	
    if (adSize.width <= 0 || adSize.height <= 0) {
        if ([self respondsToSelector:@selector(adViewBannerAnimationType)]
            && AdViewBannerAnimationTypeNone != [self adViewBannerAnimationType])
            return;
    }
	
    [UIView beginAnimations:@"AdResize" context:nil];
    [UIView setAnimationDuration:0.7];
    CGRect newFrame = adView.frame;
    newFrame.size.height = adSize.height;
    newFrame.size.width = adSize.width;
    newFrame.origin.x = (self.view.bounds.size.width - adSize.width)/2;
    adView.frame = newFrame;
    [UIView commitAnimations];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // remove all notification for self
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UILabel *)label {
    return (UILabel *)[self.view viewWithTag:1337];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.adView.delegate = nil;
    self.adView = nil;
    [super dealloc];
}

#pragma mark Button handlers

- (IBAction)requestNewAd:(id)sender {
    self.label.text = @"Request New Ad pressed! Requesting...";
    [adView requestFreshAd];
}

- (IBAction)requestNewConfig:(id)sender {
    self.label.text = @"Request New Config pressed! Requesting...";
    [adView updateAdViewConfig];
}

- (IBAction)rollOver:(id)sender {
    self.label.text = @"Roll Over pressed! Requesting...";
    [adView rollOver];
}

- (IBAction)showModalView:(id)sender {
    ModalViewController *modalViewController = [[[ModalViewController alloc] init] autorelease];
    
#ifdef __IPHONE_6_0
    [self presentViewController:modalViewController animated:YES completion:nil];
#else
    [self presentModalViewController:modalViewController animated:YES];
#endif
}

- (IBAction)toggleRefreshAd:(id)sender {
    UISwitch *switch1 = (UISwitch *)[self.view viewWithTag:SIMPVIEW_SWITCH_1_TAG];
    if (switch1.on) {
        [adView startAutoRefresh];
    }
    else {
        [adView clearAdsAndStopAutoRefresh];        //stopAutoRefresh
    }
}

- (void)showAdSizeLabel {
    UIButton *button5 =(UIButton*)[self.view viewWithTag:SIMPVIEW_BUTTON_5_TAG];
    
    NSString *lableStr = @"auto --> next";
    switch (gSimpAdSize) {
        case AdviewBannerSize_320x50:lableStr = @"320x50 -->next"; break;
        case AdviewBannerSize_300x250:lableStr = @"300x250 -->next"; break;
        case AdviewBannerSize_480x60:lableStr = @"480x60 -->next"; break;
        case AdviewBannerSize_728x90:lableStr = @"728x90 -->next"; break;
        default:
            break;
    }
    
    [button5 setTitle:lableStr forState:UIControlStateNormal];
}

- (IBAction)changeAdSize:(id)sender {
    int toAdSize = (AdviewBannerSize_Auto==gSimpAdSize)?(gSimpAdSize+2):(gSimpAdSize+1);
    if (toAdSize > AdviewBannerSize_728x90)
        toAdSize = AdviewBannerSize_Auto;
    
    gSimpAdSize = toAdSize;
    [self showAdSizeLabel];
}

- (IBAction)toggleTestAd:(id)sender {
    UISwitch *switch2 = (UISwitch *)[self.view viewWithTag:SIMPVIEW_SWITCH_2_TAG];
    gSimpTestMode = switch2.on;
}

#pragma mark AdViewDelegate methods

- (NSString *)adViewApplicationKey {
    //if (1 == gInView%2)
        return kSampleAppKey;
    //else return kSampleAppKey1;
}

- (NSString *)BaiDuApIDString {
    return @"2f952126";				//@"debug";
}

- (NSString *)BaiDuApSpecString{
	//spec string for baidu
	return @"debug";		//2f952126_e498eab7
}

#if 0
- (NSString *)kuaiYouApIDString {//application id for kuaiYou
	return @"PMZTo0g20101117421215";
}

- (NSString *)youMiApIDString { //application id for youmi
	return @"6e9e6d15741495b6";
}

- (NSString *)woobooApIDString { //application id for wooboo
	return @"afc507fbcab54cd2b56beacaba74efdc";
}

- (NSString *)admobPublisherID {// your Publisher ID from Admob.
	return @"a14cf36f8a6185d";
}

- (NSString *)millennialMediaApIDString{ // your ApID string from Millennial Media.
	return @"15062";
}

- (NSString *)youMiApSecretString { //application secret for youmi
	return @"90d29d1be5d71a7c";
}

- (NSString *)adChinaApIDString {  //application id for adChina
	return @"69329";
}

- (NSString *)caseeApIDString{  //application id for casee
	return @"";
}

- (NSString *)WiAdApIDString{	//application id for WiYun
	return @"";
}

#endif

- (UIViewController *)viewControllerForPresentingModalView {
	//return self;
    return [((AdViewSDK_SampleAppDelegate *)[[UIApplication sharedApplication] delegate]) navigationController];
}

- (void)adViewDidReceiveAd:(AdViewView *)adViewView {
    self.label.text = [NSString stringWithFormat:
                       @"Got ad from %@, size %@",
                       [adViewView mostRecentNetworkName],
                       NSStringFromCGSize([adViewView actualAdSize])];
	AWLogInfo(@"height:%f", CGRectGetHeight(adViewView.bounds));
    [self adjustAdSize];
}

- (void)adViewDidClickAd:(AdViewView *)adViewView {
	self.label.text = [NSString stringWithFormat:
					   @"Click ad of %@, size %@",
					   [adViewView mostRecentNetworkName],
					   NSStringFromCGSize([adViewView actualAdSize])];
}

- (void)adViewStartGetAd:(AdViewView *)adViewView {
	self.label.text = [NSString stringWithFormat:
					   @"Go to ad %@, size %@",
					   [adViewView mostRecentNetworkName],
					   NSStringFromCGSize([adViewView actualAdSize])];
	[self adjustAdSize];
}

- (void)adViewDidFailToReceiveAd:(AdViewView *)adViewView usingBackup:(BOOL)yesOrNo {
    self.label.text = [NSString stringWithFormat:
                       @"Failed to receive ad from %@, %@. Error: %@",
                       [adViewView mostRecentNetworkName],
                       yesOrNo? @"will use backup" : @"will NOT use backup",
                       adViewView.lastError == nil? @"no error" : [adViewView.lastError localizedDescription]];
}

- (void)adViewDidReceiveInternet:(AdViewView*)adViewView reachability:(BOOL)bReachable {
	self.label.text = [NSString stringWithFormat:
					   @"Receive internet reachability: %@",
					   bReachable?@"YES":@"NO"];
    if (!bReachable) {
        [UIView beginAnimations:@"AdResize" context:nil];
        [UIView setAnimationDuration:0.7];
        self.adView.frame = CGRectMake(0,0,0,0);
        [UIView commitAnimations];
    }
}

- (void)adViewReceivedGenericRequest:(AdViewView *)adViewView {
    UILabel *replacement = [[UILabel alloc] initWithFrame:KADVIEW_DETAULT_FRAME];
    replacement.backgroundColor = [UIColor redColor];
    replacement.textColor = [UIColor whiteColor];
    replacement.textAlignment = UITextAlignmentCenter;
    replacement.text = @"Generic Notification";
    [adViewView replaceBannerViewWith:replacement];
    [replacement release];
    [self adjustAdSize];
    self.label.text = @"Generic Notification";
}

- (void)adViewReceivedNotificationAdsAreOff:(AdViewView *)adViewView {
    self.label.text = @"Ads are off";
}

- (void)adViewWillPresentFullScreenModal {
    AWLogInfo(@"SimpleView: will present full screen modal");
}

- (void)adViewDidDismissFullScreenModal {
    AWLogInfo(@"SimpleView: did dismiss full screen modal");
}

- (void)adViewDidReceiveConfig:(AdViewView *)adViewView {
    self.label.text = @"Received config. Requesting ad...";
}

- (BOOL)adViewTestMode {
    return gSimpTestMode;
}

- (BOOL)adViewLogMode {
    return YES;
}

- (AdviewBannerSize)PreferBannerSize {
	return gSimpAdSize;
}

- (AdViewRequestMethod)adViewRequestMethod {
    return AdViewRequestMethod_Priority;
}

- (NSString*)adViewDisablePlatformsForIpad {
	return @"";
}

- (AdViewAppAd_BgGradientType)adViewAppAdBackgroundGradientType {
	return AdViewAppAd_BgGradient_Fix;
}

- (AdViewBannerAnimationType)adViewBannerAnimationType {
	return AdViewBannerAnimationTypeRandom;
}

#if 0
- (LangSetType)PreferLangSet {
	return LangSetType_Separated;
}
#endif
#if 0
- (UIColor *)adViewAdBackgroundColor {
    return [UIColor purpleColor];
}

- (UIColor *)adViewTextColor {
    return [UIColor cyanColor];
}
#endif
#pragma mark event methods

- (void)performEvent {
    self.label.text = @"Event performed";
}

- (void)performEvent2:(AdViewView *)adViewView {
    UILabel *replacement = [[UILabel alloc] initWithFrame:KADVIEW_DETAULT_FRAME];
    replacement.backgroundColor = [UIColor blackColor];
    replacement.textColor = [UIColor whiteColor];
    replacement.textAlignment = UITextAlignmentCenter;
    replacement.text = [NSString stringWithFormat:@"Event performed, view %@", adViewView];
    [adViewView replaceBannerViewWith:replacement];
    [replacement release];
    [self adjustAdSize];
    self.label.text = [NSString stringWithFormat:@"Event performed, view %@", adViewView];
}

#pragma mark multitasking methods

- (void)enterForeground:(NSNotification *)notification {
    AWLogInfo(@"SimpleView entering foreground");
    [self.adView updateAdViewConfig];
}

@end
