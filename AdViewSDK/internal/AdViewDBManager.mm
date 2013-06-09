//
//  AdViewDBManager.mm
//  AdViewSDK
//
//  Created by zhiwen on 13-1-8.
//
//

#include "AdViewDBManager.h"

static NSMutableArray *gAdViewDBMgrArr = nil;

@interface AdViewDBManager(PRIVATE)

- (NSString*)path;
- (id)initWithPath:(NSString*)path;

@end

@implementation AdViewDBManager

+ (id)sharedDBManagerWithPath:(NSString*)path
{
    if (nil == gAdViewDBMgrArr) {
        gAdViewDBMgrArr = [[NSMutableArray alloc] initWithCapacity:1];
    }
    @synchronized (gAdViewDBMgrArr) {
        if (nil == gAdViewDBMgrArr) {
            gAdViewDBMgrArr = [[NSMutableArray alloc] initWithCapacity:1];
        }
        for (AdViewDBManager *mgr in gAdViewDBMgrArr) {
            if ([path isEqualToString:[mgr path]]) {
                return mgr;
            }
        }
        AdViewDBManager *mgr = [[AdViewDBManager alloc] initWithPath:path];
        [gAdViewDBMgrArr addObject:mgr];
        [mgr release];
        return mgr;
    }
}

+ (void)closeDBManager:(AdViewDBManager*)mgr
{
    if (nil == gAdViewDBMgrArr) return;
    @synchronized (gAdViewDBMgrArr) {
        if ([mgr retainCount] > 1) {
            return;
        }
        
        [gAdViewDBMgrArr removeObject:mgr];
        if ([gAdViewDBMgrArr count] < 1) {
            [gAdViewDBMgrArr release];
            gAdViewDBMgrArr = nil;
        }
    }
}

#pragma mark private method
            
- (NSString*)path {
    return _path;
}

- (id)initWithPath:(NSString*)path
{
    self = [super init];
    if (nil != self) {
        _path = [path retain];
        if(sqlite3_open([path UTF8String], &_database) != SQLITE_OK)
        {
            _database = nil;
        }
    }
    return self;
}

- (void)dealloc {
    [_path release];
    _path = nil;
    
    if (nil != _database) {
        sqlite3_close(_database);
        _database = nil;
    }
    
    [super dealloc];
}

#pragma mark sql method.

- (BOOL)execSql:(NSString*)sql
{
    BOOL bRet = NO;
    sqlite3_stmt *statement;
    const char *sqlStr = [sql UTF8String];
    if (sqlite3_prepare_v2(self->_database, sqlStr, -1, &statement, nil) == SQLITE_OK)
    {
        int success = sqlite3_step(statement);
        sqlite3_finalize(statement);
        bRet = (success == SQLITE_DONE);
    }
    
    return bRet;
}

#pragma adview method.

- (BOOL)ensureAdViewConfigTable {
    NSString *sql = @"CREATE TABLE IF NOT EXISTS adview_config (key TEXT primary key,"\
    "time INTEGER, value BLOB)";
    
    return [self execSql:sql];
}

- (BOOL)saveAdViewConfig:(NSData*)config Key:(NSString*)key {
    BOOL bRet = NO;
    
    sqlite3_stmt *statement = NULL;
    
    if (1 > [config length]) return NO;
    
    sqlite3_int64 time = (sqlite3_int64)[[NSDate date] timeIntervalSince1970];
    
    const char* sql = "REPLACE Into adview_config(key,time,value) values(?,?,?)";   
    
    int success = sqlite3_prepare_v2(self->_database, sql, -1, &statement, NULL);
    if (success == SQLITE_OK)
    {
        sqlite3_bind_text(statement, 1, [key UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int64(statement, 2, time);
        sqlite3_bind_blob(statement, 3, [config bytes], [config length], SQLITE_TRANSIENT);
        
        success = sqlite3_step(statement);
        sqlite3_finalize(statement);
    }
    
    bRet =  (SQLITE_OK == success || SQLITE_DONE == success);
    
    return bRet;
}

- (NSData*)loadAdViewConfig:(NSString*)key {
    NSData *ret = nil;
    
    sqlite3_stmt *statement = NULL;

    const char* sql = "Select value From adview_config where key=?";
    
    int success = sqlite3_prepare_v2(self->_database, sql, -1, &statement, NULL);
    if (success == SQLITE_OK)
    {
        sqlite3_bind_text(statement, 1, [key UTF8String], -1, SQLITE_TRANSIENT);
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            const void *bytes = sqlite3_column_blob(statement, 0);
            int length = sqlite3_column_bytes(statement, 0);
            ret = [NSData dataWithBytes:bytes length:length];
            break;
        }
        sqlite3_finalize(statement);
    }
    
    return ret;
}

@end