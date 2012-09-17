/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter.h"
#import "KOpenAPIAdView.h"


/*Adview app recommend*/

@interface AdViewAdapterKyAdView : AdViewAdNetworkAdapter <KOpenAPIAdViewDelegate> {

}

+ (AdViewAdNetworkType)networkType;

@end
