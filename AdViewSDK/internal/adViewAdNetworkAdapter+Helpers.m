/*

 AdViewAdNetworkAdapter+Helpers.m
 
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

#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewViewImpl.h"
#import "AdViewView+.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdviewObjCollector.h"

@implementation AdViewAdNetworkAdapter (Helpers)

- (void)helperNotifyDelegateOfFullScreenModal {
  // don't request new ad when modal view is on
  [[AdviewObjCollector sharedCollector] addObj:self wait:INFINITE_WAIT];
  self.nAdBlockFlag |= AdViewAdNetworkBlockFlag_PresentScreen;

  [adViewView setInShowingModalView:YES];
  if ([adViewDelegate respondsToSelector:@selector(adViewWillPresentFullScreenModal)]) {
    [adViewDelegate adViewWillPresentFullScreenModal];
  }
}

- (void)helperNotifyDelegateOfFullScreenModalDismissal {
  if ([adViewDelegate respondsToSelector:@selector(adViewDidDismissFullScreenModal)]) {
    [adViewDelegate adViewDidDismissFullScreenModal];
  }
  [adViewView setInShowingModalView:NO];
    
  if (self.nAdBlockFlag & AdViewAdNetworkBlockFlag_PresentScreen) {
    self.nAdBlockFlag &= (~AdViewAdNetworkBlockFlag_PresentScreen);
    [[AdviewObjCollector sharedCollector] performSelector:@selector(removeObj:) withObject:self afterDelay:0.1];
  }
}

- (UIColor *)helperBackgroundColorToUse {
  if ([adViewDelegate respondsToSelector:@selector(adViewAdBackgroundColor)]) {
    UIColor *color = [adViewDelegate adViewAdBackgroundColor];
    if (color != nil) return color;
  }
#if ALL_ORG_DELEGATE_METHODS			//2010.12.24, laizhiwen	
  if ([adViewDelegate respondsToSelector:@selector(backgroundColor)]) {
    UIColor *color = [adViewDelegate backgroundColor];
    if (color != nil) return color;
  }
#endif
  return adViewConfig.backgroundColor;
}

- (UIColor *)helperTextColorToUse {
  if ([adViewDelegate respondsToSelector:@selector(adViewTextColor)]) {
    UIColor *color = [adViewDelegate adViewTextColor];
    if (color != nil) return color;
  }
#if ALL_ORG_DELEGATE_METHODS			//2010.12.24, laizhiwen	
  if ([adViewDelegate respondsToSelector:@selector(textColor)]) {
    UIColor *color = [adViewDelegate textColor];
    if (color != nil) return color;
  }
#endif
  return adViewConfig.textColor;
}

- (UIColor *)helperSecondaryTextColorToUse {
  if ([adViewDelegate respondsToSelector:@selector(adViewSecondaryTextColor)]) {
    UIColor *color = [adViewDelegate adViewSecondaryTextColor];
    if (color != nil) return color;
  }
  return nil;
}

- (NSInteger)helperCalculateAge {
#if ALL_ORG_DELEGATE_METHODS	
  NSDate *birth = [adViewDelegate dateOfBirth];
  if (birth == nil) {
    return -1;
  }
  NSDate *today = [[NSDate alloc] init];
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *components = [gregorian components:NSYearCalendarUnit
                                              fromDate:birth
                                                toDate:today
                                               options:0];
  NSInteger years = [components year];
  [gregorian release];
  [today release];
  return years;
#else
	return -1;
#endif
}

- (BOOL)isTestMode {
	if (nil != self.adViewDelegate
		&& [self.adViewDelegate respondsToSelector:@selector(adViewTestMode)]) {
		return [self.adViewDelegate adViewTestMode];
	}
	return NO;
}

+ (BOOL)helperIsIpad {
#if 1
	return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
	NSString *modelName = [[UIDevice currentDevice] model];
	if ([modelName rangeOfString:@"iPad" options:NSCaseInsensitiveSearch].location != NSNotFound) {
		return YES;
	}
	return NO;
#endif
}

- (BOOL)helperIsLandscape {
	if (![self helperUseLandscapeMode])
		return NO;
	
	UIDeviceOrientation orientation;
	if ([self.adViewDelegate respondsToSelector:@selector(adViewCurrentOrientation)]) {
		orientation = [self.adViewDelegate adViewCurrentOrientation];
	}
	else {
		orientation = [UIDevice currentDevice].orientation;
	}
	return UIDeviceOrientationIsLandscape(orientation);
}

+ (BOOL)helperIsRetina {
	if ([UIScreen instancesRespondToSelector:@selector(currentMode)])
		return CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size);
  	return NO;
}

- (BOOL)helperUseGpsMode 
{
	if ([adViewDelegate respondsToSelector:@selector(adGpsMode)]) {
		return [adViewDelegate adGpsMode];
	}
	return NO;
}

- (BOOL)helperUseLandscapeMode
{
	if ([adViewDelegate respondsToSelector:@selector(adViewLandscapeMode)]) {
		return [adViewDelegate adViewLandscapeMode];
	}
	return YES;
}

@end
