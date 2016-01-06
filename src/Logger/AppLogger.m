//
//  AppLogger.m
//  AppLogger
//
//  Created by Satish K Azad on 22/12/15.
//  Copyright © 2015 Satish K Azad. All rights reserved.
//

#import "AppLogger.h"

#define kLoggerDirectoryName				@"LoggerDirectory"



@interface AppLogger () 


@property (nonatomic, strong) NSOperationQueue *operationQueueLogger;

@end






@implementation AppLogger


#pragma mark - Singleton Class instance
/*
 * @returns     : Singelton instance of AppLogger
 * @Description : nil
 */
+ (instancetype)sharedLogger {
	static AppLogger *_instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_instance = [[AppLogger alloc] init];
	});
	
	return _instance;
}






- (instancetype)init {
	self = [super init];
	if (self) {
		//Custom Initializations
		_logApplicationStates = YES;
		[self registerGlobalExceptionHandler];
		[self createLoggerDirectoryIfNeeded];
		[self registerNotificationsForApplicationStates];
	}
	return self;
}




- (void)setLogApplicationStates:(BOOL)logApplicationStates {
	if (_logApplicationStates == logApplicationStates) {
		return;
	}
	
	_logApplicationStates = logApplicationStates;
	[self registerNotificationsForApplicationStates];
}





- (NSOperationQueue *)operationQueueLogger {
	if (!_operationQueueLogger) {
		_operationQueueLogger = [[NSOperationQueue alloc] init];
		_operationQueueLogger.maxConcurrentOperationCount = 1;
		_operationQueueLogger.name = @"AppLoggerOperationQueue";
	}
	return _operationQueueLogger;
}



#pragma mark === Global Exception Catch  =====
- (void)registerGlobalExceptionHandler {
	
	NSSetUncaughtExceptionHandler(&catchGlobalException);
	signal(SIGABRT, signalHandler);
	signal(SIGILL, signalHandler);
	signal(SIGSEGV, signalHandler);
	signal(SIGFPE, signalHandler);
	signal(SIGBUS, signalHandler);
	signal(SIGPIPE, signalHandler);
}



void signalHandler(int signal) {
	
	//Unhandled Signal
	[[AppLogger sharedLogger] logObjects:[NSNumber numberWithInt:signal], nil];
}


void catchGlobalException(NSException *exception) {
	
	[[AppLogger sharedLogger] logException:exception];
	
}





- (void)logException:(NSException *)exception {
	
	//Stack Symbols
	NSArray *stackSymbols = [exception callStackSymbols];
	
	//Stack Return Address
	NSArray *returnAddresses = exception.callStackReturnAddresses;
	
	
	//Class and Method name in which Exception Occured
	NSString *productName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", productName];
	NSArray *filteredArray = [stackSymbols filteredArrayUsingPredicate:predicate];
	NSString *classAndMethod = filteredArray.firstObject;
	
	
	//Basic Details
	NSString *exceptionName = exception.name;
	NSString *exceptionReason = exception.reason;
	NSString *description = exception.description;
	NSDictionary *userInfo = exception.userInfo;
	
	
	[[AppLogger sharedLogger] logMessage:@"EXCEPTION OCCURED:"
	 "\nNAME: %@ "
	 "\nREASON: %@ "
	 "\nDESCRIPTION: %@ "
	 "\nUSER INFO: %@ "
	 "\nClass And Method: %@ \n\n\n"
	 "\nSTACK SYMBOLS: %@"
	 "\n\n\nSTACK RETURN ADDRESSS: %@", exceptionName, exceptionReason, description, userInfo, classAndMethod, stackSymbols, returnAddresses];
}



#pragma mark ========= Logger Directory =========
- (NSString *)logDirectoryPath {
	if (!_logDirectoryPath) {
		_logDirectoryPath = [self createLoggerDirectoryIfNeeded];
	}
	return _logDirectoryPath;
}



- (NSString *)createLoggerDirectoryIfNeeded {
	
	NSString *loggerDir = [self applicationLoggerDirectoryPath];
	BOOL isDir = NO;
	NSError *error = nil;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:loggerDir isDirectory:&isDir]) {
		if (isDir) {
			return loggerDir;
		}
	}
	
	
	//Directory not exists. Create it.
	BOOL isCreated = [[NSFileManager defaultManager] createDirectoryAtPath:loggerDir
											   withIntermediateDirectories:NO
																attributes:nil
																	 error:&error];
	
	if (isCreated) {
		return loggerDir;
	}
	NSLog(@"ERROR in creating directory: %@", error);
	
	return nil;
}




- (NSString *)applicationLoggerDirectoryPath {
	
	NSString *documentDirectoryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString *loggersDirectoryPath = [documentDirectoryPath stringByAppendingPathComponent:kLoggerDirectoryName];
	
	return loggersDirectoryPath;
}









#pragma mark =========  Logger File Path  =========
- (NSString *)loggerFilePath {
	
	NSString *fileName = [self fileNameWithTimeStamp];
	NSString *filePath = [[self applicationLoggerDirectoryPath] stringByAppendingPathComponent:fileName];
	
	
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		NSString *logHeader = [[@"LOGGERS \n\nLOG GENERATED: " stringByAppendingString:fileName] stringByAppendingString:@"\n\n\n"];
		
		BOOL isFileCreated = [[NSFileManager defaultManager] createFileAtPath:filePath
																	 contents:[logHeader dataUsingEncoding:NSUTF8StringEncoding]
																   attributes:@{
																				@"File Detail": @"Logegr File"
																				}];
		if (!isFileCreated) {
			NSLog(@"ERROR in Creating Log File: %@", filePath);
			return nil;
		}
	}
	
	return filePath;
}


- (NSString *)fileNameWithTimeStamp {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd"];
	
	NSString *strDate = [formatter stringFromDate:[NSDate date]];
	
	return [strDate stringByAppendingString:@".log"];
}














#pragma mark ========= Write Logs in File  =========
- (void)writeLogData:(NSData *)logData  {
	
	NSString *logFilePath = [self loggerFilePath];
	
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
	
	if (fileHandle == nil) {
		NSLog(@"File Not Available.");
		return;
	}
	
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		
		[fileHandle seekToEndOfFile];
		NSString *formatter = [NSString stringWithFormat:@"\n\n=====================%@===============================\n\n", [NSDate date]];
		
		[fileHandle writeData:[formatter dataUsingEncoding:NSUTF8StringEncoding]];
		[fileHandle writeData:logData];
		[fileHandle writeData:[@"\n\n=====================END===============================" dataUsingEncoding:NSUTF8StringEncoding]];
		[fileHandle writeData:[@"\n///////////////////////////////////////////////////////\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
		
		[fileHandle closeFile];
	}];
	
	[self.operationQueueLogger addOperation:operation];
}



- (void)logMessage:(NSString *)arguments, ... {
	
	va_list ap;
	va_start(ap, arguments);
	
	NSString *logString = [[NSString alloc] initWithFormat:arguments arguments:ap];
	
	[self writeLogData:[logString dataUsingEncoding:NSUTF8StringEncoding]];
}


- (void)logObjects:(id)object, ... NS_REQUIRES_NIL_TERMINATION {
	
	va_list args;
	va_start(args, object);
	
	NSString *str = [NSString stringWithFormat:@"%@", object];
	NSString *logString = [[NSString alloc] initWithFormat:str arguments:args];
	
	[self logObject:logString];
	
	va_end(args);
}


- (void)logObject:(id)object {
	NSString *str = [NSString stringWithFormat:@"%@", object];

	[self writeLogData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}














#pragma mark ========= Application Life Cycle Status  =========
- (void)registerNotificationsForApplicationStates {
	if (!_logApplicationStates) {
		//Unregister
		@try {
			[[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIApplicationDidFinishLaunchingNotification];
		}
		@catch (NSException *exception) {
			[self logException:exception];
		}
		
		@try {
			[[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIApplicationDidEnterBackgroundNotification];
		}
		@catch (NSException *exception) {
			[self logException:exception];
		}

		
		@try {
			[[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIApplicationWillEnterForegroundNotification];
		}
		@catch (NSException *exception) {
			[self logException:exception];
		}
		
		
		@try {
			[[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIApplicationWillTerminateNotification];
		}
		@catch (NSException *exception) {
			[self logException:exception];
		}

		return;
	}
	
	//Register
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationLaunched:) name:UIApplicationDidFinishLaunchingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEntersInBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEntersInForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];

}


//Selectors
- (void)applicationLaunched:(NSNotification *)notification {
	[self logMessage:@"%s", __FUNCTION__];
}

- (void)applicationDidEntersInBackground:(NSNotification *)notification {
	[self logMessage:@"%s", __FUNCTION__];
}


- (void)applicationWillEntersInForeground:(NSNotification *)notification {
	[self logMessage:@"%s", __FUNCTION__];
}


- (void)applicationWillTerminate:(NSNotification *)notification {
	[self logMessage:@"%s", __FUNCTION__];
}








#pragma mark ========= Log Device Informations  =========




@end








