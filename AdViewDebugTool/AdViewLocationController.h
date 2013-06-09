//
//  AdViewLocationController.h
//  AdViewSDK_Sample
//
//  Copyright 2010 www.adview.cn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManager.h>
#import "TableController.h"

@interface AdViewLocationController : TableController <CLLocationManagerDelegate> {
  CLLocationManager *locationManager;
  UIInterfaceOrientation currLayoutOrientation;
}

@property (nonatomic,readonly) UILabel *locLabel;

- (void)adjustLayoutToOrientation:(UIInterfaceOrientation)newOrientation;

@end
