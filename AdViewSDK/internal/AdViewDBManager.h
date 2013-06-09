//
//  AdViewDBManager.h
//  AdViewSDK
//
//  Created by zhiwen on 13-1-8.
//
//

#ifndef __AdViewSDK__AdViewDBManager__
#define __AdViewSDK__AdViewDBManager__

#include <sqlite3.h>

@interface AdViewDBManager : NSObject {
    sqlite3 *_database;
    NSString *_path;
}

+ (id)sharedDBManagerWithPath:(NSString*)path;
+ (void)closeDBManager:(AdViewDBManager*)mgr;

- (BOOL)execSql:(NSString*)sql;

#pragma mark adview method.

- (BOOL)ensureAdViewConfigTable;
- (BOOL)saveAdViewConfig:(NSData*)config Key:(NSString*)key;
- (NSData*)loadAdViewConfig:(NSString*)key;

@end


#endif /* defined(__AdViewSDK__AdViewDBManager__) */
