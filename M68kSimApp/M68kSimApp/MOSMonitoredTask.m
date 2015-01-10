//
//  MOSMonitoredTask.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 09/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSMonitoredTask.h"
#import "NSFileHandle+Strings.h"


@implementation MOSMonitoredTask


- init {
  self = [super init];
  
  task = [[NSTask alloc] init];
  outputPipe = [[NSPipe alloc] init];
  lines = [[NSMutableArray alloc] init];
  running = NO;
  didLaunch = NO;
  exitSem = dispatch_semaphore_create(0);
  
  [task setStandardError:outputPipe];
  [task setStandardOutput:outputPipe];
  
  return self;
}

- (NSArray*)arguments {
  return [task arguments];
}


- (void)setArguments:(NSArray*)args {
  [task setArguments:args];
}


- (NSURL*)currentDirectoryURL {
  NSString *path;
  
  path = [task currentDirectoryPath];
  if (!path) return nil;
  return [[NSURL alloc] initFileURLWithPath:path];
}


- (void)setCurrentDirectoryURL:(NSURL*)url {
  if (![url isFileURL]) {
    [NSException raise:@"MOSMonitoredTaskFileURLExpected"
      format:@"setCurrentDirectoryURL: expected a file URL but got %@.", url];
  }
  [task setCurrentDirectoryPath:[url path]];
}


- (NSDictionary*)environment {
  return [task environment];
}


- (void)setEnvironment:(NSDictionary*)env {
  [task setEnvironment:env];
}


- (NSURL*)launchURL {
  NSString *path;
  
  path = [task launchPath];
  if (!path) return nil;
  return [[NSURL alloc] initFileURLWithPath:path];
}


- (void)setLaunchURL:(NSURL*)url {
  if (![url isFileURL]) {
    [NSException raise:@"MOSMonitoredTaskFileURLExpected"
                format:@"setCurrentDirectoryURL: expected a file URL but got %@.", url];
  }
  [task setLaunchPath:[url path]];
}


- (int)processIdentifier {
  return [task processIdentifier];
}


- (id)standardInput {
  return [task standardInput];
}


- (void)setStandardInput:(id)infh {
  [task setStandardInput:infh];
}


- (NSArray*)taskOutput {
  return [lines copy];
}


- (id)delegate {
  return delegate;
}


- (void)setDelegate:(id)del {
  delegate = del;
}


- (void)launch {
  if (didLaunch) {
    [NSException raise:NSInvalidArgumentException
      format:@"Tried to launch a task more than one time."];
  }
  didLaunch = YES;
  
  [task launch];
  running = YES;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    [task waitUntilExit];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self willChangeValueForKey:@"running"];
      running = NO;
      [self didChangeValueForKey:@"running"];
    });
    dispatch_semaphore_signal(exitSem);
  });
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    NSFileHandle *outFh;
    NSString *line;
    
    outFh = [outputPipe fileHandleForReading];
    line = [outFh readLine];
    while (line) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self willChangeValueForKey:@"taskOutput"];
        [lines addObject:line];
        [self didChangeValueForKey:@"taskOutput"];
        [delegate receivedTaskOutput:line];
      });
      line = [outFh readLine];
    }
  });
}

- (void)waitUntilExit {
  if (!didLaunch) return;
  dispatch_semaphore_wait(exitSem, DISPATCH_TIME_FOREVER);
  dispatch_semaphore_signal(exitSem);
}


- (void)terminate {
  [task terminate];
}


- (BOOL)isRunning {
  return running;
}


- (int)terminationStatus {
  return [task terminationStatus];
}


- (NSTaskTerminationReason)terminationReason {
  return [task terminationReason];
}


@end
