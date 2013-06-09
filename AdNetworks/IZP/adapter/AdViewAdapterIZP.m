/*
 
 Copyright 2010 www.adview.cn. All rights reserved.
 
 */

#import "AdViewAdapterIZP.h"
#import "AdViewView.h"
#import "AdViewViewImpl.h"
#import "AdViewAdNetworkRegistry.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkConfig.h"
#import "AdviewObjCollector.h"
#import "adViewLog.h"

@implementation AdViewAdapterIZP

+ (AdViewAdNetworkType)networkType {
	return AdViewAdNetworkTypeIZPTec;
}

+ (void)load {
    if (NSClassFromString(@"IZPView") != nil) {
        [[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];        
    }
}

- (void)getAd{
    NSString* apID = @"";
    Class izpViewClass = NSClassFromString(@"IZPView");
    if (izpViewClass == nil) {
        return;
    }

    if ([adViewDelegate respondsToSelector:@selector(izpApIDString)]) {
		apID = [adViewDelegate izpApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
	
	[self updateSizeParameter];

    IZPView *adView = [[izpViewClass alloc] initWithFrame:self.rSizeAd];
	if (nil == adView) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}
	
    adView.productID = apID;
    adView.adType = @"1";
    adView.isDev = [adViewDelegate adViewTestMode];
    adView.delegate = self;
    
    self.bWaitAd = YES;
    [adView startAdExchange];
    
    self.adNetworkView = adView;
    [adView release];
    [self setupDummyHackTimer:14];
}

- (void)stopBeingDelegate {
    AWLogInfo(@"IZP stopBeingDelegate %@", self);
    IZPView *adView = (IZPView *)self.adNetworkView;
    [adView stopAdExchange];
    adView.delegate = nil;
    self.adNetworkView = nil;
}

- (void)cleanupDummyRetain {
    AWLogInfo(@"IZP cleanupDummyRetain %@", self);
    [super cleanupDummyRetain];
    
    IZPView *adView = (IZPView *)self.adNetworkView;
    [adView stopAdExchange];
	if (self.bWaitAd) {
        self.adViewView = nil;
		[[AdviewObjCollector sharedCollector] addObj:self wait:180];
    }
}

- (void)updateSizeParameter {
    /*
     * auto for iphone, auto for ipad,
     * 320x50, 300x250,
     * 480x60, 728x90
     */
    CGSize sizeArr[] = {CGSizeMake(320, 48), CGSizeMake(768, 90),
        CGSizeMake(320, 48), CGSizeMake(320, 48),
        CGSizeMake(320, 48), CGSizeMake(768, 90)};
    
    [self setSizeParameter:nil size:sizeArr];
}

- (void)dealloc {
	[super dealloc];
}

/*
 *错误报告
 * 
 *详解:code 是错误代码  info是对错误的说明
 * 1：系统错误 2：参数错误 3：接口不存在 4：应用被冻结 5：无合适广告 6：应用用户不存在 7:请求广告时无法建立连接 8：请求广告时发生连接错误 9：解析广告出错  10 11 12 ：没能成功请求到广告资源  100：没有产品id  101:没有广告类型
 */
- (void) errorReport:(IZPView*)view  errorCode:(NSInteger)code erroInfo:(NSString*) info {
    AWLogInfo(@"IZP errorReport %@", self);
    self.bWaitAd = NO;
    [self cleanupDummyHackTimer];
    
    if (self.adNetworkView) {
        [view stopAdExchange];
    }
    [adViewView adapter:self didFailAd:[NSError errorWithDomain:info code:code userInfo:nil]];
}


/*
 *成功请求到一则广告
 *
 *详解:count代表请求到第几条广告，从1开始，累加计数
 */
- (void)didReceiveFreshAd:(IZPView*)view adCount:(NSInteger)count {
    self.bWaitAd = NO;
    [self cleanupDummyHackTimer];
    if (self.adNetworkView)
        [view stopAdExchange];
    [adViewView adapter:self didReceiveAdView:view];
}

/*
 请求广告失败
 
 详解:info 是错误代码，此时请求广告不会自动停止。-3:请求图片出错 -2:xml解析错误 -1：没能建立连接 
 */
- (void)didFailToReceiveFreshAd:(IZPView*)view errorInfo:(NSString*)info {
    self.bWaitAd = NO;
    [self cleanupDummyHackTimer];
    if (self.adNetworkView)
        [view stopAdExchange];
    [adViewView adapter:self didFailAd:[NSError errorWithDomain:info code:-1 userInfo:nil]];
}
 


/*用户停止贴片广告
 *
 *详解:在显示全屁贴片广告的时候，当用户点击了跳过按钮时候，调用此方法。此时广告请求已经停止，
 *
 */
- (void)didStopFullScreenAd:(IZPView*)view {
}



/*
 *
 *用户点击广告后将切换到浏览器
 *
 */

- (void)willLeaveApplication:(IZPView*)adView {

}
@end
