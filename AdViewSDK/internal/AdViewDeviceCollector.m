//
//  AdViewDeviceCollector.m
//  AdViewDeviceCollector
//  Created by Zhang Kerberos on 11-9-9.
//  Copyright 2011年 Access China. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "AdViewDeviceCollector.h"
#import "AdViewReachability.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "adViewLog.h"
#import "AdViewExtraManager.h"

#define ADVIEW_UUID_KEY @"Adview_Unique_Id"

#define ADVIEW_DEVICE_COLLECTOR_REPORT_HOST @"report.adview.cn"
#define ADVIEW_DEVICE_COLLECTOR_REPORT_FORMAT @"http://%@/agent/appReport.php?keyAdView=%@&keyDev=%@&typeDev=%@&osVer=%@&resolution=%@&servicePro=%@&netType=%@&channel=%@&platform=%@"

typedef enum {
    kAdViewDeviceCollectorStatusNotPost = 0,
    kAdViewDeviceCollectorStatusPosting,
    kAdViewDeviceCollectorStatusPosted,
    kAdViewDeviceCollectorStatusMax,
} AdViewDeviceCollectorStatus;

static AdViewDeviceCollector* shared_adview_device_collector = nil;
static AdViewDeviceCollectorStatus shared_adview_device_collector_status = kAdViewDeviceCollectorStatusNotPost;

@implementation AdViewDeviceCollector
@synthesize delegate;
@synthesize uuid;

+ (AdViewDeviceCollectorStatus) deviceCollectorStatus
{
    return shared_adview_device_collector_status;
}

+ (AdViewDeviceCollector*) sharedDeviceCollector
{
    @synchronized ([AdViewDeviceCollector class]) {
        if (shared_adview_device_collector == nil) {
            shared_adview_device_collector = [[AdViewDeviceCollector alloc] init];
        }
    }
    return shared_adview_device_collector;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized ([AdViewDeviceCollector class]) {
        if (shared_adview_device_collector == nil) {
            shared_adview_device_collector = [super allocWithZone:zone];
        }
    }
    return shared_adview_device_collector;
}

typedef unsigned int uint;
typedef unsigned char BYTE;

static uint CRC32(const BYTE* ptr,uint Size)
{
    
	uint crcTable[256],crcTmp1;
	
	//动态生成CRC-32表
	for (int i=0; i<256; i++)
    {
		crcTmp1 = i;
		for (int j=8; j>0; j--)
		{
			if (crcTmp1&1) crcTmp1 = (crcTmp1 >> 1) ^ 0xEDB88320L;
			else crcTmp1 >>= 1;
		}
		
		crcTable[i] = crcTmp1;
    }
	//计算CRC32值
	uint crcTmp2= 0xFFFFFFFF;
	while(Size--)
	{
		crcTmp2 = ((crcTmp2>>8) & 0x00FFFFFF) ^ crcTable[ (crcTmp2^(*ptr)) & 0xFF ];
		ptr++;
	}
	
	return (crcTmp2^0xFFFFFFFF);
}

#define XOR_VAL		0x8254F076
#define ADD_VAL		0x1056832D

+ (NSString*)encodeString:(NSString*)inStr {
	const char *strData = [inStr UTF8String];
	uint inLen = strlen(strData);
	uint crc32Val = CRC32((const BYTE*)strData, inLen);
	
	crc32Val ^= XOR_VAL;
	crc32Val += ADD_VAL;
	
	NSString *strAppend = [NSString stringWithFormat:@"%X", crc32Val];
	return [NSString stringWithFormat:@"%@-%@", inStr, strAppend];
}

+ (NSString*)decodeString:(NSString*)inStr {
	if (nil == inStr) return nil;
	
	NSRange range = [inStr rangeOfString:@"-" options:NSBackwardsSearch];
	if (range.location == NSNotFound) return nil;
	
	NSString *ret = [inStr substringToIndex:range.location];
	NSString *crc32Str = [inStr substringFromIndex:range.location+1];
#if 0
	unsigned long crc32Long = 0;
	sscanf([crc32Str UTF8String], "%lx", &crc32Long);
	
	uint crc32Val = (uint)crc32Long;
	crc32Val -= ADD_VAL;
	crc32Val ^= XOR_VAL;
#endif
	const char *strData = [ret UTF8String];
	uint inLen = strlen(strData);
	uint crc32Cal = CRC32((const BYTE*)strData, inLen);
	
	crc32Cal ^= XOR_VAL;
	crc32Cal += ADD_VAL;
	
	NSString *strAppend = [NSString stringWithFormat:@"%X", crc32Cal];	
	
	if ([strAppend isEqualToString:crc32Str])
		return ret;
	
	return nil;
}

+ (NSString *)myIdentifier 
{
	AdViewDeviceCollector *collector = [AdViewDeviceCollector sharedDeviceCollector];
	
	if (nil != collector.uuid)
		return collector.uuid;
    
#if 1
    collector.uuid = [[AdViewExtraManager createManager] getMacAddress];
    return collector.uuid;
#else
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *uuidEnc = [defaults objectForKey:ADVIEW_UUID_KEY];

	NSString *uuid = [AdViewDeviceCollector decodeString:uuidEnc];
	
	if (nil == uuid || [uuid length] > 60) {
        CFUUIDRef uuidRef = CFUUIDCreate(NULL);  
        CFStringRef uuidStr = CFUUIDCreateString(NULL, uuidRef);
		
		uuid = [NSString stringWithFormat:@"ADV-%@", uuidStr];
		
        CFRelease(uuidStr);
        CFRelease(uuidRef);
		
		NSString *e1 = [AdViewDeviceCollector encodeString:uuid];
		[defaults setObject:e1 forKey:ADVIEW_UUID_KEY];
		[defaults synchronize];
	}
	
	AWLogInfo(@"uuid length:%d", [uuid length]);
	
	collector.uuid = uuid;
	return uuid;
#endif
}

- (NSUInteger) retainCount {
    return NSUIntegerMax;
}

- (oneway void) release {
    
}

- (id) retain {
    return shared_adview_device_collector;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        //[self deviceInformation];
    }
    
    return self;
}

- (void)dealloc
{
	self.delegate = nil;
	self.uuid = nil;
	
    [super dealloc];
}

- (NSString*) urlEncode: (NSString*) string
{
    NSMutableString *escaped = [NSMutableString stringWithString: [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSRange wholeString = NSMakeRange(0, escaped.length);
    [escaped replaceOccurrencesOfString:@"$" withString:@"%24" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@" " withString:@"%20" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:wholeString];
    return escaped;
}
- (void)postDeviceInformation
{
    if (shared_adview_device_collector_status == kAdViewDeviceCollectorStatusNotPost) {
        //post
        shared_adview_device_collector_status = kAdViewDeviceCollectorStatusPosting;
        NSString* appKey = @"testkey/%fadsfa";
        NSString* marketChannel = @"";
        if ([self.delegate respondsToSelector:@selector(appKey)]) {
            appKey = [self.delegate performSelector:@selector(appKey)];
        }
        if ([self.delegate respondsToSelector:@selector(marketChannel)]) {
            marketChannel = [self.delegate performSelector:@selector(marketChannel)];
        }
        NSString* report_url = [NSString stringWithFormat:ADVIEW_DEVICE_COLLECTOR_REPORT_FORMAT,
								ADVIEW_DEVICE_COLLECTOR_REPORT_HOST,
                                [self urlEncode:appKey],
                                [self urlEncode: [self deviceId]],
                                [self urlEncode: [self deviceModel]],
                                [self urlEncode: [self systemVersion]],
                                [self urlEncode: [self screenResolution]],
                                [self urlEncode: [self serviceProviderCode]],
                                [self urlEncode: [self networkType]],
                                [self urlEncode: marketChannel],
                                [self urlEncode: [self systemName]]
                                ];
        AWLogInfo(@"%@", report_url);
        NSURL *url = [NSURL URLWithString: report_url];
        NSURLRequest *req = [NSURLRequest requestWithURL:url];
        [NSURLConnection connectionWithRequest:req delegate:self];
    }
}

- (NSString*) deviceId
{
    return [AdViewDeviceCollector myIdentifier];//[[UIDevice currentDevice] uniqueIdentifier];
}

- (NSString*) deviceModel
{
    return [[UIDevice currentDevice] model];
}

- (NSString*) systemVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString*) systemName
{
    return [[UIDevice currentDevice] systemName];
}

- (NSString*) screenResolution
{
    NSString* screenResolution = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // iPad
        screenResolution = @"1024*768";
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        // iPhone
        screenResolution = @"480*320";
    } else {
        // Unknown
        screenResolution = @"Unknown";
    }
    
    return screenResolution;
}

- (NSString*) serviceProviderCode
{
    NSString* serviceProviderCode;
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    //NSString *carrierName = [carrier carrierName];
    NSString *carrierCountryCode = [carrier mobileCountryCode];
    NSString *carrierNetworkCode = [carrier mobileNetworkCode];
    NSString* deviceModel = [[UIDevice currentDevice] model];
    NSRange simulatorRange = [deviceModel rangeOfString:@"Simulator"];
    if (simulatorRange.location != NSNotFound) {
        serviceProviderCode = @"Unknown";
    } else {
        serviceProviderCode = [NSString stringWithFormat:@"%@%@", carrierCountryCode, carrierNetworkCode];
    }
    [netinfo release];
    return serviceProviderCode;
}

- (NSString*) networkType
{
    NSString* netType = nil;
    AdViewNetworkStatus netStatus = [[AdViewReachability reachabilityForInternetConnection] currentReachabilityStatus];
    switch (netStatus) {
        case AdViewNotReachable:
            netType = @"Unknown";
            break;
        case AdViewReachableViaWiFi:
            netType = @"Wi-Fi";
            break;
        case AdViewReachableViaWWAN:
            netType = @"2G/3G";
            break;
        default:
            break;
    }
    return netType;
}

#pragma mark - URLConnection
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    shared_adview_device_collector_status = kAdViewDeviceCollectorStatusNotPost;
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    AWLogInfo(@"Recive Data %@", string);
    [string release];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    shared_adview_device_collector_status = kAdViewDeviceCollectorStatusPosted;
}
@end