//
//  UMAdBannerView.h
//  UMAds
//
//  Created by luyiyuan on 9/13/11.
//  Copyright (c) 2011 umeng.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UMAdADBannerViewDelegate;

@interface UMAdBannerView : UIView
{
@private
    id _delegate;
    id _storage;
}
@property (nonatomic, assign) id <UMAdADBannerViewDelegate> delegate;

/** 
 
 根据设备自动获取BannerSize,iPhone 320x50 iPad 480x75
 @return CGSize 当前设备应该返回广告Banner的长宽
 
 */
+ (CGSize)sizeOfBannerContentSize;
/** 
 
 自主请求banner的Size尺寸，320x50为iphone版本
 @return CGSize 
 
 */
+ (CGSize)bannerSizeofSize320x50;
/** 
 
 获取banner的size尺寸支持，480x75为ipad版本
 @return CGSize 
 
 */
+ (CGSize)bannerSizeofSize480x75;
/** 
 
 设置banner的广告属性，绑定相关参数
 @return void
 @param viewController  为点击后可能全屏的WebView提供PresentingModalView的父Controller
 @param slotid          当前Banner绑定的广告位id
 
 */
- (void)setProperty:(UIViewController *)viewController slotid:(NSString *)slotid;
/** 
 
 为Banner设定delegate，这样delegate可以监听banner的一些动作，如获取失败，点击等等
 @return void
 @param delegate 实现UMAdADBannerViewDelegate的Class
 
 */
- (void)setDelegate:(id<UMAdADBannerViewDelegate>)delegate;
@end

@protocol UMAdADBannerViewDelegate <NSObject>
@optional
/** 
 
 bannerView已经获取数据，并加载
 @return void
 @param banner 当前事件属于的bannerview
 
 */
- (void)UMADBannerViewDidLoadAd:(UMAdBannerView *)banner;
/** 
 
 bannerView获取内容失败
 @return void
 @param banner 当前事件属于的bannerview
 @param error  出错具体信息，error code可与UMAdManager.h中的UMADError对照
 
 */
- (void)UMADBannerView:(UMAdBannerView *)banner didFailToReceiveAdWithError:(NSError *)error;
/** 
 
 bannerview点击事件即将开始
 @return void
 @param banner 当前事件属于的bannerview
 
 */
- (void)UMADBannerViewActionWillBegin:(UMAdBannerView *)banner;
/** 
 
 bannerview点击事件已经完毕
 @return void
 @param banner 当前事件属于的bannerview
 
 */
- (void)UMADBannerViewActionDidFinish:(UMAdBannerView *)banner;
@end
