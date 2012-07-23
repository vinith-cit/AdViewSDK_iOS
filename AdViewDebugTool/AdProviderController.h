//
//  AdProviderController.h
//  AdViewHello
//
//  Created by the user on 12-7-12.
//  Copyright (c) 2012年 Access China. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AdProviderController : UITableViewController

@property (retain) NSDictionary *adProviders;

- (void)setAllAdProviders:(BOOL)bEnable Except:(int)type;

@end
