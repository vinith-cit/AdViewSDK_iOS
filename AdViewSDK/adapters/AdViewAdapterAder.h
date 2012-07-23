/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter+helpers.h"
#import "AderDelegateProtocal.h"


/*Ader*/

@interface AdViewAdapterAder : AdViewAdNetworkAdapter <AderDelegateProtocal> {

}

+ (AdViewAdNetworkType)networkType;

@end
