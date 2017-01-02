//
//  MOSMonitoredTask.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 09/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Foundation/Foundation.h>


@protocol MOSMonitoredTaskDelegate

- (void)receivedTaskOutput:(NSString*)line;
  
@end


/* Like NSTask, but it automatically reads the line-based stdout and stderr
 * of the task. */

@interface MOSMonitoredTask : NSObject {
  id<MOSMonitoredTaskDelegate> delegate;
  dispatch_semaphore_t exitSem;
  dispatch_semaphore_t pipeClosedSem;
  NSTask *task;
  NSPipe *outputPipe;
  NSMutableArray *lines;
  BOOL running;
  BOOL didLaunch;
}

- (NSArray*)arguments;
- (void)setArguments:(NSArray*)args;
- (NSURL*)currentDirectoryURL;
- (void)setCurrentDirectoryURL:(NSURL*)url;
- (NSDictionary*)environment;
- (void)setEnvironment:(NSDictionary*)env;
- (NSURL*)launchURL;
- (void)setLaunchURL:(NSURL*)url;
- (int)processIdentifier;

- (id)delegate;
- (void)setDelegate:(id)del;

- (id)standardInput;
- (void)setStandardInput:(id)infh;
- (NSArray*)taskOutput;

- (void)launch;
- (void)terminate;
- (void)waitUntilExit;

- (BOOL)isRunning;
- (int)terminationStatus;
- (NSTaskTerminationReason)terminationReason;

@end
