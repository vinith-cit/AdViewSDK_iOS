//
//  AdViewController.h
//  AdViewANESDK
//
//  Created by the user on 12-7-30.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdViewView.h"

#define AD_POS_CENTER      -1           //center in horizontal or vertical
#define AD_POS_REWIND      -2           //right or bottom

#define IS_VIEWCONTROLLER             0

#if IS_VIEWCONTROLLER
#define CONTROLLER_SUPER_CLASS      UIViewController
#else
#define CONTROLLER_SUPER_CLASS      NSObject
#endif

@protocol AdViewControllerDelegate <NSObject>

@required
- (void)didGotNotify:(NSString*)code Info:(NSString*)content;
@end

@interface AdViewController : CONTROLLER_SUPER_CLASS <AdViewDelegate> {
    AdViewView          *adView_;
    CGFloat             ad_x;         //-1 means center in horizontal
    CGFloat             ad_y;         //-1 means center in vertical
    BOOL                ad_hidden;      //YES for hidden    
    
    BOOL                adTestMode;
    BOOL                adLogMode;
    NSString            *adviewKey;
    int                 nOrientationSupport;
    
    int                 nOrientation;
    
    BOOL                bSuperOrientFix;        //like game, super view is fixed as (320, 480)
    
    AdViewRequestMethod nRequestMethod;
}

@property (nonatomic,retain) AdViewView         *adView;
@property (nonatomic,assign) AdviewBannerSize   adBannerSize;
@property (nonatomic,assign) UIViewController   *adRootController;
@property (nonatomic,assign) id<AdViewControllerDelegate> notifyDelegate;
@property (nonatomic,assign) AdViewRequestMethod nRequestMethod;

@property (nonatomic,assign) BOOL bSuperOrientFix;

+ (AdViewController*) sharedController;
+ (AdViewController*) sharedControllerIfExists;
+ (void) deleteController;

+ (void)setAllAdProviders:(BOOL)bVal Except:(int)type;

- (void)setAdViewKey:(NSString*)key;
- (void)setModeTest:(BOOL)bTest Log:(BOOL)bLog;

- (void)setAdPosition:(CGPoint)start;           //x = -1, means center in horizontal
//y = -1, means center in vertical

- (CGPoint)getAdPosition;                       //for restore.

- (void)loadView;

- (void)setAdHidden:(BOOL)bHidden;
- (void)setOrientationUp:(BOOL)bUp Down:(BOOL)bDown Left:(BOOL)bLeft Right:(BOOL)bRight;

- (void)addAdView;
- (void)adjustAdSize;

- (void)rollOver;
- (void)requestNewAd;

@end

#ifdef __cplusplus
#define BEGIN_C_LINKAGE extern "C" {
#define END_C_LINKAGE }
#else
#define BEGIN_C_LINKAGE
#define END_C_LINKAGE
#endif

BEGIN_C_LINKAGE
void setAdViewAdVLog(BOOL bLog);
void _AdViewAdVLogInfo(NSString *format, ...);

#define AdVLogInfo _AdViewAdVLogInfo

void doAdViewNotifyApp(NSString *code, NSString *content);       //call to app.
END_C_LINKAGE