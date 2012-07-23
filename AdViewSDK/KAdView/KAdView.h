#import <UIKit/UIKit.h>

@class KAdView;

@protocol KAdViewDelegate <NSObject>

@optional
-(UIColor*)adTextColor;
-(UIColor*)adBackgroundColor;
-(void)didReceivedAd:(KAdView*)adView;
-(void)didFailToReceiveAd:(KAdView*)adView Error:(NSError*)error;

-(NSString*) kAdViewHost;
-(int)autoRefreshInterval;
-(int)gradientBgType;		//-1, none, 0 - fix, 1 - random

@required

-(NSString*) appId;
-(BOOL) testMode;

@end

@interface KAdView : UIView

#define KADVIEW_SIZE_320x44		CGSizeMake(320, 44)
#define KADVIEW_SIZE_480x44		CGSizeMake(480, 44)
#define KADVIEW_SIZE_320x270	CGSizeMake(320, 270)
#define KADVIEW_SIZE_480x80		CGSizeMake(480, 80)
#define KADVIEW_SIZE_760x110	CGSizeMake(760, 110)

@property (nonatomic, assign) id<KAdViewDelegate> delegate;

+(KAdView*) requestOfSize: (CGSize) size withDelegate: (id<KAdViewDelegate>) delegate;
+(KAdView*) requestWithDelegate: (id<KAdViewDelegate>) delegate;
+(NSString*) sdkVersion;

-(void) pauseRequestAd;
-(void) resumeRequestAd;

@end
