/*
 
 Copyright 2010 www.adview.cn. All rights reserved.
 
 */

#import "AdViewAdNetworkAdapter.h"
#import "IZPView.h"
#import "IZPDelegate.h"

@interface AdViewAdapterIZP : AdViewAdNetworkAdapter <IZPDelegate> {
    NSTimer *timer;
}
- (void)loadAdTimeOut:(NSTimer*)theTimer;
@end
