//
//  SingletonAdapterBase.m
//  AdViewSDK
//
//  Created by zhiwen on 12-1-13.
//  Copyright 2012 www.adview.cn. All rights reserved.
//

#import "SingletonAdapterBase.h"
#import "AdViewLog.h"

@implementation SingletonAdapterBase

@synthesize mAdapter;
@synthesize mIdelViewArr;
@synthesize mLockObj;

- (id)init {
	self = [super init];
	if (self) {
		self.mLockObj = [[[NSObject alloc] init] autorelease];
		self.mIdelViewArr = [[[NSMutableArray alloc] initWithCapacity:10] autorelease];
	}
	return self;
}

- (void)dealloc {
	[mIdelViewArr release];
	[mLockObj release];
	
	self.mLockObj = nil;
	self.mIdelViewArr = nil;
	
	[super dealloc];
}

- (void)setAdapterValue:(BOOL)bSetOrClean ByAdapter:(AdViewAdNetworkAdapter*)adapter {
	@synchronized (mLockObj) {
		if (bSetOrClean)
			mAdapter = adapter;
		else if (mAdapter == adapter)
			mAdapter = nil;
	}
}

- (void)updateAdFrame:(UIView*)view {
}

- (UIView*)getIdelAdView {
	UIView *ret = nil;
	
	@synchronized (mLockObj) {
		if ([mIdelViewArr count] > 0) {
			ret = [[mIdelViewArr objectAtIndex:[mIdelViewArr count]-1] retain];
			[mIdelViewArr removeLastObject];
			[self updateAdFrame:ret];
		}
		else {
			return [self makeAdView];
		}
	}
	return [ret autorelease];
}

- (UIView*)makeAdView {
	return nil;
}

- (void)addIdelAdView:(UIView*)view {
	@synchronized (mLockObj) {
		[mIdelViewArr addObject:view];
	}
}

- (BOOL)isTestMode {
	@synchronized (mLockObj) {
		if (nil != mAdapter
			&& [mAdapter.adViewDelegate respondsToSelector:@selector(adViewTestMode)]) {
			return [mAdapter.adViewDelegate adViewTestMode];
		}
	}
	return NO;
}

- (BOOL)isAdViewValid:(UIView*)adView {
	@synchronized (mLockObj) {
		if (nil == mAdapter 
			|| (nil != mAdapter.adNetworkView && mAdapter.adNetworkView != adView)) {
				AWLogInfo(@"--Singleton %@ stale delegate call --------", NSStringFromClass([self class]));
				return NO;
		}
	}
	return YES;
}

@end
