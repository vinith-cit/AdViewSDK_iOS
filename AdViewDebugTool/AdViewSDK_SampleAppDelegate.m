/*

 AdViewSDK_SampleAppDelegate.m
 
 Copyright 2010 www.adview.cn

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
*/

#import "AdViewSDK_SampleAppDelegate.h"
#import "RootViewController.h"
#import "adViewLog.h"

@interface AdViewUIApplication : UIApplication

@end

@implementation AdViewUIApplication

- (BOOL)openURL:(NSURL*)url {
    BOOL ret = [super openURL:url];
    
    if (ret) {
        NSLog(@"openURL:%@", url);
    }
    
    return ret;
}

- (void)sendEvent:(UIEvent *)event {
    //no thing.
    if (event.type == UIEventTypeTouches)
    {
    }
    
    [super sendEvent:event];
}

@end

@implementation AdViewSDK_SampleAppDelegate

@synthesize window;
@synthesize navigationController;


#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {
#ifdef ADWHIRL_DEBUG
  ADVLogSetLogLevel(AWLogLevelDebug);
#endif
	[window addSubview:[navigationController view]];
#ifdef __IPHONE_6_0
    window.rootViewController = navigationController;
#endif
  [window makeKeyAndVisible];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}


@end

