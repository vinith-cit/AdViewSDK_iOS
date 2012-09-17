#import <UIKit/UIKit.h>
#import <CoreLocation/CLLocationManager.h>

@class KOpenAPIAdView;

@protocol KOpenAPIAdViewDelegate <NSObject>

@optional
-(UIColor*)adTextColor;
-(UIColor*)adBackgroundColor;
-(void)didReceivedAd:(KOpenAPIAdView*)adView;
-(void)didFailToReceiveAd:(KOpenAPIAdView*)adView Error:(NSError*)error;

-(NSString*) KOpenAPIAdViewHost;
-(int)autoRefreshInterval;	//<=0 - none, <10 - 10, unit: seconds
-(int)gradientBgType;		//-1 - none, 0 - fix, 1 - random

-(UIViewController*)viewControllerForShowModal;

- (void)adViewWillPresentScreen:(KOpenAPIAdView *)adView;
- (void)adViewDidDismissScreen:(KOpenAPIAdView *)adView;

@required

-(NSString*) appId;
-(BOOL) testMode;
-(BOOL) logMode;

@end

@interface KOpenAPIAdView : UIView

#define KOPENAPIADVIEW_SIZE_320x48		CGSizeMake(320, 48)
#define KOPENAPIADVIEW_SIZE_480x44		CGSizeMake(480, 44)
#define KOPENAPIADVIEW_SIZE_300x250		CGSizeMake(300, 250)
#define KOPENAPIADVIEW_SIZE_480x60		CGSizeMake(480, 60)
#define KOPENAPIADVIEW_SIZE_728x90		CGSizeMake(728, 90)

#define KOPENAPIADTYPE_DEFAULT		0			//adview app ad
#define KOPENAPIADTYPE_SUIZONG		1			//suizong

@property (nonatomic, assign) id<KOpenAPIAdViewDelegate> delegate;
@property (nonatomic, retain) CLLocation*				location;

+(KOpenAPIAdView*) requestOfSize:(CGSize)size withDelegate:(id<KOpenAPIAdViewDelegate>)delegate 
					  withAdType:(int)adType;
+(KOpenAPIAdView*) requestWithDelegate:(id<KOpenAPIAdViewDelegate>)delegate
							withAdType:(int)adType;
+(NSString*) sdkVersion;

-(void) pauseRequestAd;
-(void) resumeRequestAd;

@end
