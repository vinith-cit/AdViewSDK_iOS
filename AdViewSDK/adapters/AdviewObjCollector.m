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

#define COLLECT_TIME	120.0f

static AdviewObjCollector *gObjCollector = nil;


@interface AdviewObjCollectItem : NSObject
{
}

@property (nonatomic, retain) NSObject			*objVal;
@property (nonatomic, assign) NSTimeInterval	timeVal;
@property (nonatomic, assign) int               waitVal;        //wait seconds to release

@end

@implementation AdviewObjCollectItem

@synthesize objVal = _objVal;
@synthesize timeVal = _timeVal;
@synthesize waitVal = _waitVal;

- (id)init {
    self = [super init];
    if (self) {
        self.waitVal = COLLECT_TIME;
    }
    return self;
}

-(void) dealloc{
	//AWLogInfo(@"retain:%d", [self.objVal retainCount]);
	
	self.objVal = nil;
	self.timeVal = 0;
    self.waitVal = 0;
	
	[super dealloc];
}

@end


@implementation AdviewObjCollector

@synthesize arrObjs;

- (id)init {
	self = [super init];
	if (nil != self) {
		self.arrObjs = [[[NSMutableArray alloc] initWithCapacity:8] autorelease];
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
            if (INFINITE_WAIT == advItem.waitVal) continue;
            
			if (advItem.timeVal + advItem.waitVal < nowTi)
			{//need release
				iFind = i;
			} else {
				if ([advItem.objVal isKindOfClass:[AdViewAdNetworkAdapter class]])
				{
					AdViewAdNetworkAdapter *adapter = (AdViewAdNetworkAdapter*)advItem.objVal;
					if (!adapter.bWaitAd
                        && AdViewAdNetworkWaitFlag_None == adapter.nAdWaitFlag
                        && AdViewAdNetworkBlockFlag_None == adapter.nAdBlockFlag)
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
		
		for (int i = iFind; i >= 0; i--) {
            AdviewObjCollectItem *advItem = [self.arrObjs objectAtIndex:i];
            //if blocked adapter, won't dealloc.
            if ([advItem.objVal isKindOfClass:[AdViewAdNetworkAdapter class]])
            {
                AdViewAdNetworkAdapter *adapter = (AdViewAdNetworkAdapter*)advItem.objVal;
                
                if (adapter.nAdBlockFlag != AdViewAdNetworkBlockFlag_None)
                    continue;
                adapter.nAdWaitFlag = AdViewAdNetworkWaitFlag_None;     //set as not wait.
            }
            if (INFINITE_WAIT == advItem.waitVal) continue;     //no need release.
            
			[self.arrObjs removeObjectAtIndex:i];
            nRelease ++;
        }

		if (nRelease > 0)
			AWLogInfo(@"AdviewObjCollector released %d, left %d", nRelease, [self.arrObjs count]);		
		
		[self addTimer];
	}
}

- (void)addObj:(NSObject*)obj
{
    [self addObj:obj wait:COLLECT_TIME];
}

- (void)addObj:(NSObject*)obj wait:(int)seconds
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
        advItem.waitVal = seconds;
		[self.arrObjs addObject:advItem];
		[advItem release];
		
		[self addTimer];
	}
}

- (void)removeObj:(NSObject*)obj
{
    @synchronized(lockObj) {
        if (nil == obj) return;
        
        NSMutableArray *arrDone = [[NSMutableArray alloc] initWithCapacity:10];
        for (int i = 0; i < [self.arrObjs count]; i++)
        {
            AdviewObjCollectItem *advItem = [self.arrObjs objectAtIndex:i];
            if (obj == advItem.objVal) {
                [arrDone addObject:[NSNumber numberWithInt:i]];
            }
        }
		for (int i = [arrDone count]-1; i >= 0; i--) {
			NSNumber *numIndex = (NSNumber*)[arrDone objectAtIndex:i];
			[self.arrObjs removeObjectAtIndex:[numIndex intValue]];
		}
        if ([arrDone count] > 0) {
            AWLogInfo(@"AdviewObjCollector remove %d objs.", [arrDone count]);
        }
		[arrDone release];
    }
}

- (void)setAdapterAdViewViewNil:(NSObject*)_adView
{
    @synchronized(lockObj) {
        NSMutableArray *arrDone = [[NSMutableArray alloc] initWithCapacity:10];
		for (int i = 0; i < [self.arrObjs count]; i++)
		{
			AdviewObjCollectItem *advItem = [self.arrObjs objectAtIndex:i];
			
			if (nil == advItem) continue;
			if ([advItem.objVal isKindOfClass:[AdViewAdNetworkAdapter class]])
            {
                AdViewAdNetworkAdapter *adapter = (AdViewAdNetworkAdapter*)advItem.objVal;
                if ((NSObject*)adapter.adViewView == _adView)
                {
                    adapter.adViewView = nil;
                    adapter.adViewDelegate = nil;
                    if (INFINITE_WAIT == advItem.waitVal) {
                        [adapter cleanupDummyRetain];
                        [arrDone addObject:[NSNumber numberWithInt:i]];
                    }
                }
            }
		}
		for (int i = [arrDone count]-1; i >= 0; i--) {
			NSNumber *numIndex = (NSNumber*)[arrDone objectAtIndex:i];
			[self.arrObjs removeObjectAtIndex:[numIndex intValue]];
		}
        if ([arrDone count] > 0) {
            AWLogInfo(@"AdviewObjCollector remove %d objs.", [arrDone count]);
        }
		[arrDone release];
    }
}

- (void)dealloc {
	self.arrObjs = nil;
	[lockObj release];		lockObj = nil;
	[cTimer invalidate];	cTimer = nil;
	
	[super dealloc];
}

@end
