/*

 AdViewConfigStore.m

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

#import "AdViewConfigStore.h"
#import "AdViewLog.h"
#import "AWNetworkReachabilityWrapper.h"
#import "AdViewError.h"

#import "AdViewViewImpl.h"

#import "CJSONSerializer.h"
#import "AdViewExtraManager.h"
#import "AdViewDBManager.h"

#define kAdViewConfigRegetTimeInteval		1800.		//seconds


#define CONFIG_FILE_NAME		@"Library/adview_config.dat"
#define CONFIG_FILE_DB          @"Library/adview_config.db"


static AdViewConfigStore *gStore = nil;

@interface AdViewConfigStore ()

- (BOOL)checkFileExists:(NSString*)path;
- (void)startParseConfig;
- (BOOL)checkReachability;
- (void)startFetchingAssumingReachable;
- (void)failedFetchingWithError:(AdViewError *)error;
- (void)finishedFetching;

@end


@implementation AdViewConfigStore

@synthesize reachability = reachability_;
@synthesize connection = connection_;
@synthesize fetchingConfig = fetchingConfig_;

+ (AdViewConfigStore *)sharedStore {
  if (gStore == nil) {
    gStore = [[AdViewConfigStore alloc] init];
  }
  return gStore;
}

+ (void)resetStore {
  if (gStore != nil) {
    [gStore release], gStore = nil;
    [self sharedStore];
  }
}

- (id)init {
  self = [super init];
  if (self != nil) {
    configs_ = [[NSMutableDictionary alloc] init];
      
      NSString *dbPath = [NSHomeDirectory()
                     stringByAppendingPathComponent:CONFIG_FILE_DB];
      dbManager = [AdViewDBManager sharedDBManagerWithPath:dbPath];
      [dbManager ensureAdViewConfigTable];
  }
  return self;
}

- (void)setNeedParseConfig {
    for (AdViewConfig *config in [configs_ allValues])
        config.needParse = YES;
}

- (AdViewConfig*)getBufferConfig:(NSString*)appKey
{
    AdViewConfig *config = [configs_ objectForKey:appKey];
    if (config != nil) return config;
    
    NSData *data = [dbManager loadAdViewConfig:appKey];
    if (nil != data) {
        AdViewError *advErr = nil;
        AdViewConfig *config = [[AdViewConfig alloc] initWithAppKey:appKey
                                                           delegate:nil];
        BOOL bParse = [config parseConfig:data error:&advErr];
        if (!bParse) {
            [config release];
            return nil;
        }
        return [config autorelease];
    }
    return nil;
}

- (AdViewConfig *)getConfig:(NSString *)appKey
                    delegate:(id<AdViewConfigDelegate>)delegate {
  AdViewConfig *config = [configs_ objectForKey:appKey];
  if (config != nil) {
    if (config.hasConfig) {
		NSDate *nowDate = [[NSDate alloc] init];
		NSTimeInterval diff = [nowDate timeIntervalSinceDate:config.getDataDate];
		[nowDate release];
		
		if (diff > kAdViewConfigRegetTimeInteval) {//30 minutes,30. * 60
#if 0			
			return [self fetchConfig:appKey blockMode:YES delegate:delegate];
#else
			return [self fetchFileConfig:appKey
                               blockMode:YES
								  method:ConfigMethod_DataFile 
								delegate:delegate];
#endif			
		}
		else if (config.needParse) {
			AdViewConfig *config1 = [[AdViewConfig alloc] initWithAppKey:appKey
															   delegate:delegate];
            BOOL    bKeyChanged = ![self.fetchingConfig.appKey isEqualToString:appKey];
            
			config1.fetchBlockMode = YES;
			config1.fetchType = config.fetchType | FetchTypeMemory;
			self.fetchingConfig = config1;
			//[configs_ setObject:config1 forKey:appKey];
			[config1 release];
            
            if (bKeyChanged) {
                NSData *data = [dbManager loadAdViewConfig:appKey];
                if (nil != data) {
                    [receivedData_ setLength:0];
                    [receivedData_ appendData:data];
                }
            }
			
			[self performSelectorOnMainThread:@selector(startParseConfig)
								   withObject:self
								waitUntilDone:NO];
			return config1;
		}
		
      if ([delegate
           respondsToSelector:@selector(adViewConfigDidReceiveConfig:)]) {
        // Don't call directly, instead schedule it in the runloop. Delegate
        // may expect the message to be delivered out-of-band
        [(NSObject *)delegate
         performSelectorOnMainThread:@selector(adViewConfigDidReceiveConfig:)
                          withObject:config
                       waitUntilDone:NO];
      }
      return config;
    }
    // If there's already a config fetching, and another call to this function
    // add a delegate to the config
    [config addDelegate:delegate];
    return config;
  }

  // No config, create one, and start fetching it
#if 0
	return [self fetchConfig:appKey blockMode:YES delegate:delegate];
#else
	return [self fetchFileConfig:appKey blockMode:YES
                          method:ConfigMethod_DataFile delegate:delegate];
#endif
}

- (AdViewConfig *)fetchConfig:(NSString *)appKey
					blockMode:(BOOL)block
                      delegate:(id <AdViewConfigDelegate>)delegate {
  if (nil == appKey) {
      AWLogWarn(@"Nil appKey, can not get config.");
      return nil;
  }

  AdViewConfig *config = [[AdViewConfig alloc] initWithAppKey:appKey
                                                       delegate:delegate];
	config.fetchBlockMode = block;
  if (self.fetchingConfig != nil) {
    AWLogWarn(@"Another fetch is in progress, wait until finished.");
    [config release];
    return nil;
  }
  self.fetchingConfig = config;

	reachCheckNum = 0;
  if (![self checkReachability]) {
    [config release];
    return nil;
  }

  config.fetchType = FetchTypeNetwork;
  //[configs_ setObject:config forKey:appKey];
  [config release];
  return config;
}

- (AdViewConfig *)fetchFileConfig:(NSString *)appKey
						blockMode:(BOOL)block
						   method:(ConfigMethod)cfgMethod
						 delegate:(id <AdViewConfigDelegate>)delegate 
{	
	AdViewConfig *config = [[AdViewConfig alloc] initWithAppKey:appKey
                                                       delegate:delegate];
	config.fetchBlockMode = block;
	if (self.fetchingConfig != nil) {
		AWLogWarn(@"Another fetch is in progress, wait until finished.");
		[config release];
		return nil;
	}
	self.fetchingConfig = config;
	
	//[configs_ setObject:config forKey:appKey];
	[config release];
	
    if (nil == receivedData_)
        receivedData_ = [[NSMutableData alloc] init];
	NSData *data = nil;
	NSString *filePath_in = nil;
	
	if (cfgMethod == ConfigMethod_DataFile) {
        data = [dbManager loadAdViewConfig:appKey];
        
        if (nil == data) {
            filePath_in = [NSHomeDirectory()
							 stringByAppendingPathComponent:CONFIG_FILE_NAME];
            BOOL bExist = [self checkFileExists:filePath_in];
            AWLogInfo(@"data config path:%@, exit:%d", filePath_in, bExist);
            if (bExist) {
                data = [NSData dataWithContentsOfFile:filePath_in];
                
                //save to db, and remove this.
                [dbManager saveAdViewConfig:data Key:appKey];
                [[NSFileManager defaultManager] removeItemAtPath:filePath_in error:nil];
            }
        }
	} else if (cfgMethod == ConfigMethod_OfflineFile) {
		NSString *offFileName = [appKey stringByAppendingString:@".txt"];
		filePath_in = [[[NSBundle mainBundle] bundlePath]
					   stringByAppendingPathComponent:offFileName];
		
		NSData *fileData = nil;
		BOOL bExist = [self checkFileExists:filePath_in];
		AWLogInfo(@"offline config path:%@, exit:%d", filePath_in, bExist);
		if (bExist) {
			fileData = [NSData dataWithContentsOfFile:filePath_in];
		}
		
		NSError *jsonError = nil;
		id parsed = [[CJSONDeserializer deserializer] deserialize:fileData 
															error:&jsonError];
		if (parsed != nil && [parsed isKindOfClass:[NSDictionary class]]) {
			BOOL isDeviceForeign = [AdViewConfig isDeviceForeign];
			NSString *cfg_key = isDeviceForeign?@"foreign_cfg":@"china_cfg";
			NSObject *dic = [(NSDictionary*)parsed objectForKey:cfg_key];
			if (nil == dic) dic = parsed;			//maybe it is off location setting.
			if ([dic isKindOfClass:[NSDictionary class]])
				data = [[CJSONSerializer serializer] serializeDictionary:(NSDictionary*)dic
																   error:nil];
		}		
	}
	[receivedData_ setLength:0];
	[receivedData_ appendData:data];
	
	config.fetchType = FetchTypeFile;
    [self performSelectorOnMainThread:@selector(startParseConfig)
                           withObject:self
                        waitUntilDone:NO];
	return config;
}

- (void)dealloc {
  if (reachability_ != nil) {
    reachability_.delegate = nil;
    [reachability_ release];
  }
  [connection_ release];
  [receivedData_ release];	receivedData_ = nil;
  [configs_ release];

    [AdViewDBManager closeDBManager:dbManager];
    dbManager = nil;
    
  [super dealloc];
}


#pragma mark private helper methods

// Check reachability first
- (BOOL)checkReachability {
  AWLogInfo(@"Checking if config is reachable at %@",
             self.fetchingConfig.configURL);

  // Normally reachability_ should be nil so a new one will be created.
  // In a testing environment, it may already have been assigned with a mock.
  // In any case, reachability_ will be released when the config URL is
  // reachable, in -reachabilityBecameReachable.
  if (reachability_ == nil) {
    reachability_ = [AWNetworkReachabilityWrapper
                     reachabilityWithHostname:[self.fetchingConfig.configURL host]
                     callbackDelegate:self];
    [reachability_ retain];
  }
  if (reachability_ == nil) {
    [self.fetchingConfig notifyDelegatesOfFailure:
     [AdViewError errorWithCode:AdViewConfigConnectionError
                     description:
      @"Error setting up reachability check to config server"]];
    return NO;
  }

  if (!CONFIG_REACH_CHECK) {
	  [self reachabilityBecameReachable:reachability_];
  }
  else if (![reachability_ scheduleInCurrentRunLoop]) {
    [self.fetchingConfig notifyDelegatesOfFailure:
     [AdViewError errorWithCode:AdViewConfigConnectionError
                     description:
      @"Error scheduling reachability check to config server"]];
    [reachability_ release], reachability_ = nil;
    return NO;
  }

  return YES;
}

// Make connection
- (void)startFetchingAssumingReachable {
  // go fetch config
  NSURLRequest *configRequest
    = [NSURLRequest requestWithURL:self.fetchingConfig.configURL];

  // Normally connection_ should be nil so a new one will be created.
  // In a testing environment, it may alreay have been assigned with a mock.
  // In any case, connection_ will be release when connection failed or
  // finished.
  if (connection_ == nil) {
    connection_ = [[NSURLConnection alloc] initWithRequest:configRequest
                                                  delegate:self];
  }

  // Error checking
  if (connection_ == nil) {
    [self failedFetchingWithError:
     [AdViewError errorWithCode:AdViewConfigConnectionError
                     description:
                                @"Error creating connection to config server"]];
    return;
  }
  if (nil != receivedData_)
    receivedData_ = [[NSMutableData alloc] init];
}

// Clean up after fetching failed
- (void)failedFetchingWithError:(AdViewError *)error {
  // notify
  [self.fetchingConfig notifyDelegatesOfFailure:error];

  // remove the failed config from the cache
  // [configs_ removeObjectForKey:self.fetchingConfig.appKey];
  // the config is only retained by the dict,now released

    [connection_ release], connection_ = nil;
    //[receivedData_ release], receivedData_ = nil;
    self.fetchingConfig = nil;
}

// Clean up after fetching, success or failed
- (void)finishedFetching {
  [configs_ setObject:self.fetchingConfig forKey:self.fetchingConfig.appKey];
    
  [connection_ release], connection_ = nil;
  //[receivedData_ release], receivedData_ = nil;
  self.fetchingConfig = nil;
}

// config file exist? last saved?
- (BOOL)checkFileExists:(NSString*)path {
	NSFileManager *manage = [NSFileManager defaultManager];
	
	BOOL ret = [manage fileExistsAtPath:path]
		&& [manage isReadableFileAtPath:path];
	if (!ret) {
	}
	return ret;
}

- (void)startParseConfig {
	AdViewError *advErr = nil;
	BOOL bParse = [self.fetchingConfig parseConfig:receivedData_ error:&advErr];
	if (!bParse) [self failedFetchingWithError:advErr];
	else [self finishedFetching];
}

#pragma mark reachability methods

- (void)reachabilityNotReachable:(AWNetworkReachabilityWrapper *)reach {
	++reachCheckNum;
	if (reachCheckNum >= 3) {
		AWLogInfo(@"check reachable over time >= 3");
		[self failedFetchingWithError:
		 [AdViewError errorWithCode:AdViewConfigConnectionError
						description:
		  @"Error config server not reachable!"]];
		[reachability_ release], reachability_ = nil;
		return;
	}
  if (reach != reachability_) {
    AWLogWarn(@"Unrecognized reachability object called not reachable %s:%d",
              __FILE__, __LINE__);
    return;
  }
  AWLogInfo(@"Config host %@ not (yet) reachable, check back later",
             reach.hostname);
  [reachability_ release], reachability_ = nil;
  [self performSelector:@selector(checkReachability)
             withObject:nil
             afterDelay:10.0];
}

- (void)reachabilityBecameReachable:(AWNetworkReachabilityWrapper *)reach {
  if (reach != reachability_) {
    AWLogWarn(@"Unrecognized reachability object called reachable %s:%d",
              __FILE__, __LINE__);
    return;
  }
  // done with the reachability
  [reachability_ release], reachability_ = nil;

  [self startFetchingAssumingReachable];
}


#pragma mark NSURLConnection delegate methods.

- (void)connection:(NSURLConnection *)conn
                                didReceiveResponse:(NSURLResponse *)response {
  if (conn != connection_) {
    AWLogError(@"Unrecognized connection object %s:%d", __FILE__, __LINE__);
    return;
  }
  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
    NSHTTPURLResponse *http = (NSHTTPURLResponse*)response;
    const int status = [http statusCode];

    if (status < 200 || status >= 300) {
      AWLogWarn(@"AdViewConfig: HTTP %d, cancelling %@", status, [http URL]);
      [connection_ cancel];
      [self failedFetchingWithError:
       [AdViewError errorWithCode:AdViewConfigStatusError
                       description:@"Config server did not return status 200"]];
      return;
    }
  }

  [receivedData_ setLength:0];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
  if (conn != connection_) {
    AWLogError(@"Unrecognized connection object %s:%d", __FILE__, __LINE__);
    return;
  }
  [self failedFetchingWithError:
   [AdViewError errorWithCode:AdViewConfigConnectionError
                   description:@"Error connecting to config server"
               underlyingError:error]];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
  if (conn != connection_) {
    AWLogError(@"Unrecognized connection object %s:%d", __FILE__, __LINE__);
    return;
  }
    
#if 1
    [dbManager saveAdViewConfig:receivedData_ Key:self.fetchingConfig.appKey];
	NSTimeInterval nowTi = [[NSDate date] timeIntervalSince1970];
    NSString *last_Key = [NSString stringWithFormat:@"%@%@", LAST_NET_CONFIG_TIME,
                          self.fetchingConfig.appKey];
	[[AdViewExtraManager createManager] storeObject:[NSNumber numberWithDouble:nowTi]
											 forKey:last_Key];
#endif
	
#if 0
	// backup config file to used if config server is down.
	NSString *filePath = [NSHomeDirectory()
						  stringByAppendingPathComponent:CONFIG_FILE_NAME];
	[receivedData_ writeToFile:filePath atomically:YES];
	
	NSTimeInterval nowTi = [[NSDate date] timeIntervalSince1970];
	[[AdViewExtraManager createManager] storeObject:[NSNumber numberWithDouble:nowTi]
											 forKey:LAST_NET_CONFIG_TIME];
#endif
    
#if 0		//modify config.txt to test adv working.
	NSString *filePath_in = [NSHomeDirectory()
						  stringByAppendingPathComponent:@"Library/config_1.dat"];
	
	NSData *data = [NSData dataWithContentsOfFile:filePath_in];
	[receivedData_ setLength:0];
	[receivedData_ appendData:data];
#endif
	
	AdViewError *advErr = nil;
	BOOL bParse = [self.fetchingConfig parseConfig:receivedData_ error:&advErr];
	if (!bParse) [self failedFetchingWithError:advErr];
	else [self finishedFetching];
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
  if (conn != connection_) {
    AWLogError(@"Unrecognized connection object %s:%d", __FILE__, __LINE__);
    return;
  }
  [receivedData_ appendData:data];
}

@end
