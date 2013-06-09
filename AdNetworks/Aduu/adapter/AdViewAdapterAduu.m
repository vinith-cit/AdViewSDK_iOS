/*
 adview openapi ad-Aduu.
*/

#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewDelegateProtocol.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "AdViewAdapterAduu.h"
#import "AdViewExtraManager.h"

@interface AdViewAdapterAduu ()
@end


@implementation AdViewAdapterAduu

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeAduu;
}

+ (void)load {
	if(NSClassFromString(@"KOpenAPIAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];	
	}
}

- (int)OpenAPIAdType {
    return KOPENAPIADTYPE_ADUU;
}

- (NSString *) appId {
	NSString *apID;
	if ([adViewDelegate respondsToSelector:@selector(aduuApIDString)]) {
		apID = [adViewDelegate aduuApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
	
	return apID;
	
#if 0
	return @"4f0acf110cf2f1e96d8eb7ea";		//4f0acf110cf2f1e96d8eb7ea
#endif
}

@end
