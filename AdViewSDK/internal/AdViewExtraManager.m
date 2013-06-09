//
//  AdViewExtraManager.m
//  AdViewSDK
//
//  Created by zhiwen on 12-7-25.
//  Copyright 2012 www.adview.cn. All rights reserved.
//

#import "AdViewExtraManager.h"
#import "adViewLog.h"
#import "AdviewObjCollector.h"
#include <sys/socket.h> // Per msqr 
#include <sys/sysctl.h> 
#include <net/if.h> 
#include <net/if_dl.h>

#define LOCATION_DELAY		300.0f		//seconds.
#define MAC_ADDR_FMT @"%02x%02x%02x%02x%02x%02x"
//#define MAC_ADDR_FMT @"%02x:%02x:%02x:%02x:%02x:%02x"

static AdViewExtraManager *gAdViewExtraManager = nil;

@implementation AdViewExtraManager

@synthesize macAddr = _macAddr;

#pragma mark private methods

- (void)stopUpdateLocations
{
	if(locationManager)
	{	
		[locationManager stopUpdatingLocation];
		locationManager.delegate = nil;
		[[AdviewObjCollector sharedCollector] addObj:locationManager];
		[locationManager release];
		locationManager = nil;
	}
}

- (void)findMyLocation {
	[self stopUpdateLocations];
	
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	locationManager.distanceFilter = 100;
	[locationManager startUpdatingLocation];
}

#pragma mark public methods

+ (AdViewExtraManager*)createManager {
	if (nil == gAdViewExtraManager) {
		gAdViewExtraManager = [[AdViewExtraManager alloc] init];
	}
	return gAdViewExtraManager;
}

+ (AdViewExtraManager*)sharedManager {
	return gAdViewExtraManager;
}

- (void)findLocation {
	if (nil != myLocation)
	{
		NSTimeInterval nowTi = [[NSDate date] timeIntervalSince1970];
		if (nowTi - myLocationTime < LOCATION_DELAY)	//not update location.
			return;
	}
	[self findMyLocation];
}

- (CLLocation*)getLocation {
	return myLocation;
}

// Return the local MAC addy 
// Courtesy of FreeBSD hackers email list 
// Accidentally munged during previous update. Fixed thanks to mlamb. 
+ (NSString*)actGetMacAddress
{ 
	int                    mib[6]; 
	size_t                len; 
	char                *buf; 
	unsigned char        *ptr; 
	struct if_msghdr    *ifm; 
	struct sockaddr_dl    *sdl; 
	
	mib[0] = CTL_NET; 
	mib[1] = AF_ROUTE; 
	mib[2] = 0; 
	mib[3] = AF_LINK; 
	mib[4] = NET_RT_IFLIST;
    
    int     idx1, idx2;
    idx1 = if_nametoindex("en0");
    idx2 = if_nametoindex("en1");
	mib[5] = (0!=idx1)?idx1:idx2;
	
	if (mib[5] == 0) {
		AWLogInfo(@"Error: if_nametoindex error\n");
		return NULL; 
	} 
	
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) { 
		AWLogInfo(@"Error: sysctl, take 1\n"); 
		return NULL; 
	} 
	
	if ((buf = malloc(len)) == NULL) { 
		AWLogInfo(@"Could not allocate memory. error!\n"); 
		return NULL; 
	} 
	
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) { 
		AWLogInfo(@"Error: sysctl, take 2");
        free(buf);
		return NULL; 
	} 
	
	ifm = (struct if_msghdr *)buf; 
	sdl = (struct sockaddr_dl *)(ifm + 1);
	ptr = (unsigned char *)LLADDR(sdl);
	
	NSString *outstring = [NSString stringWithFormat:MAC_ADDR_FMT, 
						   *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)]; 
	free(buf); 
	return [outstring uppercaseString]; 
}

- (NSString*)getMacAddress {
	if (nil == self.macAddr || [self.macAddr length] < 1)
		self.macAddr = [AdViewExtraManager actGetMacAddress];
	
	if (nil == self.macAddr) self.macAddr = @"000000000000";
	return self.macAddr;
}

- (void)storeObject:(NSObject*)obj forKey:(NSString*)keyStr
{
	if (nil == objDict) objDict = [[NSMutableDictionary alloc] initWithCapacity:4];
	[objDict setObject:obj forKey:keyStr];
}

- (NSObject*)objectStoredForKey:(NSString*)keyStr {
	return [objDict objectForKey:keyStr];
}

#pragma mark override methods

- (void)dealloc {
	[self stopUpdateLocations];
	[myLocation release];	myLocation = nil;
	
	[objDict release];
	objDict = nil;
	
	[super dealloc];
}

#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
	AWLogError(@"AdViewExtraManager Failed getting location: %@", error);
	
	[self stopUpdateLocations];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
	if (nil != myLocation) [myLocation release];
	myLocation = [newLocation retain];
	myLocationTime = [[NSDate date] timeIntervalSince1970];
	
	AWLogError(@"AdViewExtraManager got location:%f,%f", myLocation.coordinate.latitude,
			   myLocation.coordinate.longitude);
	
	[self stopUpdateLocations];
}

@end
