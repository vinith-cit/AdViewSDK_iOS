/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter.h"
#import "KOpenAPIAdView.h"


/*Adview openapi ad -- suizong.*/

@interface AdViewAdapterSuiZong : AdViewAdNetworkAdapter <KOpenAPIAdViewDelegate> {

}

+ (AdViewAdNetworkType)networkType;

@end
