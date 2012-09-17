//
//  AdviewObjCollector.m
//  AdViewSDK
//
//  Created by zhiwen on 12-7-24.
//  Copyright 2012 www.adview.cn. All rights reserved.
//

#import "AdviewObjCollector.h"
#import "adViewLog.h"
#import "AdViewAdNetworkAdapter.h"

#define TIMER_VAL	30.0f

#define COLLECT_TIME	90.0f

static AdviewObjCollector *gObjCollector = nil;


@interface AdviewObjCollectItem : NSObject
{
}

@property (nonatomic, retain) NSObject			*objVal;
@property (nonatomic, assign) NSTimeInterval	timeVal;

@end

@implementation AdviewObjCollectItem

@synthesize objVal = _objVal;
@synthesize timeVal = _timeVal;

-(void) dealloc{
	//AWLogInfo(@"retain:%d", [self.objVal retainCount]);
	
	self.objVal = nil;
	self.timeVal = 0;
	
	[super dealloc];
}

@end


@implementation AdviewObjCollector

@synthesize arrObjs;

- (id)init {
	self = [super init];
	if (nil != self) {
		self.arrObjs = [[NSMutableArray alloc] initWithCapacity:8];
		lockObj = [[NSObject alloc] init];
	}
	return self;
}

+ (AdviewObjCollector*)sharedCollector
{
	if (nil == gObjCollector) {
		gObjCollector = [[AdviewObjCollector alloc] init];
	}
	return gObjCollector;
}

- (void)addTimer {
	if (nil != cTimer) return;
	if ([self.arrObjs count] < 1) return;		//no need.
	
	cTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_VAL
														  target:self 
														selector:@selector(handleTimer)
														userInfo:nil 
														 repeats:NO];
}

- (void)handleTimer {
	@synchronized(lockObj) {
		cTimer = nil;
		
		NSTimeInterval nowTi = [[NSDate date] timeIntervalSince1970];
		
		int iFind = -1;
		
		NSMutableArray *arrDone = [[NSMutableArray alloc] initWithCapacity:10];
		
		for (int i = 0; i < [self.arrObjs count]; i++)
		{
			AdviewObjCollectItem *advItem = [self.arrObjs objectAtIndex:i];
			
			if (nil == advItem) continue;
			if (advItem.timeVal < nowTi - COLLECT_TIME)
			{//need release
				iFind = i;
			} else {
				if ([advItem.objVal isKindOfClass:[AdViewAdNetworkAdapter class]])
				{
					AdViewAdNetworkAdapter *adapter = (AdViewAdNetworkAdapter*)advItem.objVal;
					if (!adapter.bWaitAd)
						[arrDone addObject:[NSNumber numberWithInt:i]];
				}
			}
		}
		
		int nRelease = [arrDone count];
		
		for (int i = [arrDone count]-1; i >= 0; i--) {
			NSNumber *numIndex = (NSNumber*)[arrDone objectAtIndex:i];
			[self.arrObjs removeObjectAtIndex:[numIndex intValue]];
		}
		[arrDone release];
		
		for (int i = iFind; i >= 0; i--)
			[self.arrObjs removeObjectAtIndex:i];
		
		nRelease += iFind + 1;
		if (nRelease > 0)
			AWLogInfo(@"AdviewObjCollector released %d, left %d", nRelease, [self.arrObjs count]);		
		
		[self addTimer];
	}
}

- (void)addObj:(NSObject*)obj
{
	@synchronized(lockObj) {
		if (nil == obj) return;
		AdviewObjCollectItem *advItemLast = [self.arrObjs lastObject];
		if (nil != advItemLast && obj == advItemLast.objVal) return;
		
		AWLogInfo(@"AdviewObjCollector add 1, %@", obj);
		NSTimeInterval nowTi = [[NSDate date] timeIntervalSince1970];
		
		AdviewObjCollectItem *advItem = [[AdviewObjCollectItem alloc] init];
		advItem.objVal = obj;
		advItem.timeVal = nowTi;
		[self.arrObjs addObject:advItem];
		[advItem release];
		
		[self addTimer];
	}
}

- (void)dealloc {
	self.arrObjs = nil;
	[lockObj release];		lockObj = nil;
	[cTimer invalidate];	cTimer = nil;
	
	[super dealloc];
}

@end
