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


- (NSArray*)getSimulatorResponseWithLength:(int)c {
  int i;
  NSString *tmp;
  NSMutableArray *res;
  
  res = [NSMutableArray array];
  for (i=0; i<c; i++) {
    tmp = [[fromSim fileHandleForReading] readLine];
    if ([tmp isEqual:@"debug? "]) {
      if (i==1)
        NSLog(@"Simulator error. %@", res);
      else
        NSLog(@"Simulator response not complete. %d lines expected. %@", c, res);
      [[toSim fileHandleForWriting] writeString:@"\n"];
      break;
    }
    [res addObject:tmp];
  }
  return [res copy];
}


- (BOOL)runWithCommand:(NSString*)cmd {
  if (curState != MOSSimulatorStatePaused) return NO;
  if (![self sendCommandToSimulatorDebugger:cmd]) {
    curState = MOSSimulatorStateUnknown;
    return 0;
  }
  curState = MOSSimulatorStateRunning;
  
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
    NSString *temp;
    do {
      temp = [[fromSim fileHandleForReading] readLine];
      if (isSimDead) break;
      if (![temp isEqual:@"debug? "])
        NSLog(@"Simulator error %@", temp);
    } while (![temp isEqual:@"debug? "]);
    if (!isSimDead) {
      [[toSim fileHandleForWriting] writeString:@"\n"];
      curState = MOSSimulatorStatePaused;
    }
  });
  return YES;
}


- (BOOL)run {
  return [self runWithCommand:@"c"];
}


- (BOOL)stop {
  if (curState != MOSSimulatorStateRunning) return 0;
  [simTask interrupt];
  return 1;
}


- (NSArray*)disassemble:(int)cnt instructionsFromLocation:(uint32_t)loc {
  if (curState != MOSSimulatorStatePaused) return nil;
  if (![self sendCommandToSimulatorDebugger:[NSString stringWithFormat:@"u %d %d", loc, cnt]]) {
    curState = MOSSimulatorStateUnknown;
    return nil;
  }
  return [self getSimulatorResponseWithLength:cnt];
}


- (BOOL)stepIn {
  return [self runWithCommand:@"s"];
}


- (BOOL)stepOver {
  return [self runWithCommand:@"n"];
}


- (void)kill {
  [simTask terminate];
}


@end
