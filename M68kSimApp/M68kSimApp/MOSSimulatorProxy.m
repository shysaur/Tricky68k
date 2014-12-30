//
//  MOSSimulatorProxy.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MOSSimulatorProxy.h"
#import "NSFileHandle+Strings.h"


@implementation MOSSimulatorProxy


- (NSURL*)simulatorURL {
  NSBundle *cb;
  
  cb = [NSBundle mainBundle];
  return [cb URLForAuxiliaryExecutable:@"m68ksim"];
}


- initWithExecutableURL:(NSURL*)url {
  NSArray *args;
  int fildes;
  
  self = [super init];
  
  toSim = [[NSPipe alloc] init];
  fromSim = [[NSPipe alloc] init];
  args = @[@"-B", @"-d", @"-l", [url path]];
  
  simTask = [[NSTask alloc] init];
  [simTask setLaunchPath:[[self simulatorURL] path]];
  [simTask setArguments:args];
  [simTask setStandardInput:toSim];
  [simTask setStandardOutput:fromSim];
  isSimDead = NO;
  curState = MOSSimulatorStatePaused;
  [simTask launch];
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
    [simTask waitUntilExit];
    isSimDead = YES;
  });
  
  fildes = [[fromSim fileHandleForReading] fileDescriptor];
  NSLog(@"isatty: %d", isatty(fildes));
  
  return self;
}


- (BOOL)sendCommandToSimulatorDebugger:(NSString *)com {
  NSString *dbgPrmpt;
  
  if (curState != MOSSimulatorStatePaused) return 0;
  dbgPrmpt = [[fromSim fileHandleForReading] readLine];
  if (![dbgPrmpt isEqual:@"debug? "]) return 0;
  [[toSim fileHandleForWriting] writeString:com];
  [[toSim fileHandleForWriting] writeString:@"\n"];
  return 1;
}


- (BOOL)run {
  if (curState != MOSSimulatorStatePaused) return 0;
  if (![self sendCommandToSimulatorDebugger:@"c"]) {
    curState = MOSSimulatorStateUnknown;
    return 0;
  }
  curState = MOSSimulatorStateRunning;
  return 1;
}


- (BOOL)stop {
  if (curState != MOSSimulatorStateRunning) return 0;
  [simTask interrupt];
  curState = MOSSimulatorStatePaused;
  return 1;
}


- (NSArray*)disassemble:(int)cnt instructionsFromLocation:(uint32_t)loc {
  int i;
  NSString *tmp;
  NSMutableArray *res;
  
  if (curState != MOSSimulatorStatePaused) return nil;
  if (![self sendCommandToSimulatorDebugger:[NSString stringWithFormat:@"u %d %d", loc, cnt]]) {
    curState = MOSSimulatorStateUnknown;
    return nil;
  }
  res = [NSMutableArray array];
  for (i=0; i<cnt; i++) {
    tmp = [[fromSim fileHandleForReading] readLine];
    [res addObject:tmp];
  }
  return [res copy];
}


- (BOOL)stepIn {
  return 1;
}


- (BOOL)stepOver {
  return 1;
}


- (void)kill {
  [simTask terminate];
}


@end
