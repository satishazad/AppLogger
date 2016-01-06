//
//  AppLogger.h
//  AppLogger
//
//  Created by Satish K Azad on 22/12/15.
//  Copyright © 2015 Satish K Azad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface AppLogger : NSObject



//Properties
@property (nonatomic, strong) NSString *logDirectoryPath;
@property (nonatomic, assign) BOOL logApplicationStates;



/**
 * Singelton Instance to Create Logs.
 */
+ (instancetype)sharedLogger;






//Methods
- (NSString *)createLoggerDirectoryIfNeeded;
- (NSString *)applicationLoggerDirectoryPath;




//Write Logs
- (void)logMessage:(NSString *)arguments, ...;
- (void)logObject:(id)object;
- (void)logObjects:(id)object, ... NS_REQUIRES_NIL_TERMINATION;



@end
