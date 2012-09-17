//
//  BaiduMobAdView.h
//  BaiduMobAdSdk
//
//  Created by jaygao on 11-9-6.
//  Copyright 2011年 Baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaiduMobAdDelegateProtocol.h"

#define kBaiduAdViewSizeDefaultWidth 320
#define kBaiduAdViewSizeDefaultHeight 48

/**
 *  投放广告的视图接口,更多信息请查看[百度移动联盟主页](http://munion.baidu.com)
 */


@interface BaiduMobAdView : UIView {
    @private
    id<BaiduMobAdViewDelegate> delegate_;
    
    UIColor* textColor_;
    UIColor* backgroundColor_;
    CGFloat alpha_;
    BaiduMobAdViewType adType_;
    NSString* aduTag;
}

///---------------------------------------------------------------------------------------
/// @name 属性
///---------------------------------------------------------------------------------------

/**
 *  委托对象
 */
@property (nonatomic ,assign) id<BaiduMobAdViewDelegate>  delegate;

/**
 *  设置／获取当前广告（文字）的文本颜色
 */
@property (nonatomic, retain) UIColor* textColor;

/**
 *  设置／获取需要展示的广告类型
 *  @warning *重要:* 在SDK2.1中，该接口已无实现，接口保留，将在3.0中移除。
 */
@property (nonatomic) BaiduMobAdViewType AdType;

/**
 *  - 设置是否需要启动SDK的自动轮播机制
 *  - autoplayEnabled设置为YES（默认值）时，SDK会自动根据一定的时间间隔播放不同的广告。开发者无须编写额外的代码控制广告的更新和展示。request接口不可用
 *  - autoplayEnabled设置为NO（默认值）时，SDK不会主动调用第一个广告的展示，并产生回调函数 [BaiduMobAdViewDelegate willDisplayAd:]或者[BaiduMobAdViewDelegate failedDisplayAd:],
 *    开发者需要在回调函数[BaiduMobAdViewDelegate willDisplayAd:]或者[BaiduMobAdViewDelegate failedDisplayAd:]中调用request接口请求一次广告展示
 */

@property (nonatomic) BOOL autoplayEnabled;

/**
 *  预留字段
 */
@property (nonatomic, readonly) NSString* AdUnitTag;

/**
 *  当前广告位是否处于活跃（即展示）状态。
 *  BaiduMobAdView实例化并调用start之后会处于展示状态, isActive为YES。 当其他的[BaiduMobAdView]实例产生并[BaiduMobAdView start]以后，本实例的状态为等待，[BaiduMobAdView isActive]属性为NO
 *  
 */
@property (nonatomic, readonly) BOOL isActive;

/**
 *  SDK版本
 */
@property (nonatomic, readonly) NSString* Version;

/**
 *  - 开始广告展示请求,会触发所有资源的重新加载，推荐初始化以后调用一次
 *  - 会驱动一次广告展示，回调函数willDisplayAd或者failedDisplayAd中调用[BaiduMobAdView request]接口请求一次广告展示
 *  
 */
- (void) start;

/**
 *  - 高级接口
 *  - 请求广告展示，在[BaiduMobAdView autoplayEnabled]设置为NO时使用。
 *
 */
- (void) request;



@end

