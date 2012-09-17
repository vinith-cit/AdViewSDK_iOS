/*
 
 AdViewAdNetworkRegistry.m
 
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

#import "AdViewAdNetworkRegistry.h"
#import "AdViewAdNetworkAdapter.h"
#import "AdViewClassWrapper.h"
#import "adViewLog.h"

static int gExcludeTypes[] = {9, 16, 17};

@implementation AdViewAdNetworkRegistry

+ (AdViewAdNetworkRegistry *)sharedRegistry {
	static AdViewAdNetworkRegistry *registry = nil;
	if (registry == nil) {
		registry = [[AdViewAdNetworkRegistry alloc] init];
	}
	return registry;
}

- (id)init {
	self = [super init];
	if (self != nil) {
		adapterDict = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)registerClass:(Class)adapterClass {
	// have to do all these to avoid compiler warnings...
	NSInteger (*netTypeMethod)(id, SEL);
	netTypeMethod = (NSInteger (*)(id, SEL))[adapterClass methodForSelector:@selector(networkType)];
	NSInteger netType = netTypeMethod(adapterClass, @selector(networkType));
	NSNumber *key = [[NSNumber alloc] initWithInteger:netType];
	AdViewClassWrapper *wrapper = [[AdViewClassWrapper alloc] initWithClass:adapterClass];
	[adapterDict setObject:wrapper forKey:key];
	[key release];
	[wrapper release];
}

- (void)unregisterClassFor:(NSInteger)adNetworkType
{
	[adapterDict removeObjectForKey:[NSNumber numberWithInteger:adNetworkType]];
}

- (void)hideClass:(BOOL)bVal For:(NSInteger)adNetworkType
{
	AdViewClassWrapper *wrapper = [adapterDict objectForKey:[NSNumber numberWithInteger:adNetworkType]];
	if (nil == wrapper) return;
	
	wrapper.theHide = bVal;
}

- (void)enableClass:(BOOL)bEnable For:(NSInteger)adNetworkType
{
	AdViewClassWrapper *wrapper = [adapterDict objectForKey:[NSNumber numberWithInteger:adNetworkType]];
	if (nil == wrapper) return;
	
	wrapper.theEnable = bEnable;
}

- (void)listAdapterClasses {
	for (int i = 0; i < sizeof(gExcludeTypes)/sizeof(int); i++)
		[self hideClass:YES For:gExcludeTypes[i]];
	
	NSArray *keyArr = [adapterDict allKeys];
	for (int i = 0; i < [keyArr count]; i++)
	{
		NSNumber *key = (NSNumber*)[keyArr objectAtIndex:i];
		if (nil == key) continue;
		
		AdViewClassWrapper *wrapper = [adapterDict objectForKey:key];
		if (nil == wrapper || wrapper.theHide) continue;
		
		NSString *name = NSStringFromClass(wrapper.theClass);
		name = [name stringByReplacingOccurrencesOfString:@"AdViewAdapter" withString:@""];
		
		AWLogInfo(@"Adapter type:%d, class:%@ enable:%d", [key intValue], name, wrapper.theEnable);
	}
}

- (NSDictionary*)getClassesStatus 
{
	for (int i = 0; i < sizeof(gExcludeTypes)/sizeof(int); i++)
		[self hideClass:YES For:gExcludeTypes[i]];
	
	NSArray *keyArr = [adapterDict allKeys];
	NSMutableDictionary *dicInfo = [[NSMutableDictionary alloc] initWithCapacity:10];
	for (int i = 0; i < [keyArr count]; i++)
	{
		NSNumber *key = (NSNumber*)[keyArr objectAtIndex:i];
		if (nil == key) continue;
		
		AdViewClassWrapper *wrapper = [adapterDict objectForKey:key];
		if (nil == wrapper || wrapper.theHide) continue;
		
		NSString *name = NSStringFromClass(wrapper.theClass);
		
		name = [name stringByReplacingOccurrencesOfString:@"AdViewAdapter" withString:@""];
		
		NSString *info = [[NSString alloc] initWithFormat:@"%@,%d", name, wrapper.theEnable];
		[dicInfo setObject:info forKey:key];
		[info release];
	}
	
	return [dicInfo autorelease];
}

- (void)setClassesStatus:(NSDictionary*)dict
{
	NSArray *keyArr = [dict allKeys];
	for (int i = 0; i < [keyArr count]; i++)
	{
		NSNumber *key = (NSNumber*)[keyArr objectAtIndex:i];
		if (nil == key) continue;
		
		NSNumber *numVal = [dict objectForKey:key];
		if (nil == numVal) continue;
		
		AdViewClassWrapper *wrapper = [adapterDict objectForKey:key];
		if (nil == wrapper) continue;
		
		wrapper.theEnable = ([numVal intValue] != 0);
	}
}

- (AdViewClassWrapper *)adapterClassFor:(NSInteger)adNetworkType {
	AdViewClassWrapper *wrapper = [adapterDict objectForKey:[NSNumber numberWithInteger:adNetworkType]];
	
	if (nil != wrapper && !wrapper.theEnable) return nil;
	return wrapper;
}

- (void)dealloc {
	[adapterDict release], adapterDict = nil;
	[super dealloc];
}

@end
