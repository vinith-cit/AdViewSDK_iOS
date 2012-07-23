//
//  BaiduMobAdDelegateProtocol.h
//  BaiduMobAdSdk
//
//  Created by jaygao on 11-9-8.
//  Copyright 2011年 Baidu. All rights reserved.
//

/**
 *  广告banner类型
 */
typedef enum  {
    BaiduMobAdViewTypeText = 1,
    BaiduMobAdViewTypeImage = 2,
    
} BaiduMobAdViewType ;

/**
 *  广告展示失败类型枚举
 */
typedef enum _BaiduMobFailReason
{
    BaiduMobFailReason_NOAD = 0,
    // 没有推广返回
    BaiduMobFailReason_EXCEPTION 
    //网络或其它异常
} BaiduMobFailReason;

///---------------------------------------------------------------------------------------
/// @name 协议板块
///---------------------------------------------------------------------------------------

@class BaiduMobAdView;
/**
 *  广告sdk委托协议
 */
@protocol BaiduMobAdViewDelegate<NSObject>

@required
/**
 *  应用在mounion.baidu.com上的id
 */
- (NSString *)publisherId;

/**
 *  应用在mounion.baidu.com上的计费名
 */
- (NSString*) appSpec;

@optional
/**
 *  启动位置信息
 */
-(BOOL) enableLocation;

/**
 *  广告将要被载入
 */
-(void) willDisplayAd:(BaiduMobAdView*) adview;

/**
 *  广告载入失败
 */
-(void) failedDisplayAd:(BaiduMobFailReason) reason;

/**
 *  本次广告展示成功时的回调
 */
-(void) didAdImpressed;

/**
 *  本次广告展示被用户点击时的回调
 */
-(void) didAdClicked;

/**
 *  在用户点击完广告条出现全屏广告页面以后，用户关闭广告时的回调
 */
-(void) didDismissLandingPage;





@end