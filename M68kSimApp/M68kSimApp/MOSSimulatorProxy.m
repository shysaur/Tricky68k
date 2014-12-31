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


void MOSSimLog(NSTask *proc, NSString *fmt, ...) {
  NSString *mess;
  va_list ap;
  
  va_start(ap, fmt);
  mess = [[NSString alloc] initWithFormat:fmt arguments:ap];
  NSLog(@"Simulator PID %d: %@", [proc processIdentifier], mess);
  va_end(ap);
}
  


@implementation MOSSimulatorProxy


- (NSURL*)simulatorURL {
  NSBundle *cb;
  
  cb = [NSBundle mainBundle];
  return [cb URLForAuxiliaryExecutable:@"m68ksim"];
}


- initWithExecutableURL:(NSURL*)url {
  NSArray *args;
  
  self = [super init];
  
  toSim = [[NSPipe alloc] init];
  fromSim = [[NSPipe alloc] init];
  args = @[@"-B", @"-d", @"-l", [url path]];
  
  simTask = [[NSTask alloc] init];
  [simTask setLaunchPath:[[self simulatorURL] path]];
  [simTask setArguments:args];
  [simTask setStandardInput:toSim];
  [simTask setStandardOutput:fromSim];
  
  [self willChangeValueForKey:@"simulatorState"];
  isSimDead = NO;
  curState = MOSSimulatorStatePaused;
  [self didChangeValueForKey:@"simulatorState"];
  [simTask launch];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    [simTask waitUntilExit];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self willChangeValueForKey:@"simulatorState"];
      isSimDead = YES;
      [self didChangeValueForKey:@"simulatorState"];
    });
  });
  
  return self;
}


- (BOOL)sendCommandToSimulatorDebugger:(NSString *)com {
  NSString *dbgPrmpt;
  
  if (curState != MOSSimulatorStatePaused || isSimDead) return 0;
  
  dbgPrmpt = [[fromSim fileHandleForReading] readLine];
  if (![dbgPrmpt isEqual:@"debug? "]) {
    MOSSimLog(simTask, @"Can't sent command %@. Read %@ instead of prompt.", com, dbgPrmpt);
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self willChangeValueForKey:@"simulatorState"];
      curState = MOSSimulatorStateUnknown;
      [self didChangeValueForKey:@"simulatorState"];
    });
    return 0;
  }
  
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
        MOSSimLog(simTask, @"Error! %@", res);
      else
        MOSSimLog(simTask, @"Response incomplete. %d lines expected. %@", c, res);
      [[toSim fileHandleForWriting] writeString:@"\n"];
      break;
    }
    [res addObject:tmp];
  }
  return [res copy];
}


- (BOOL)runWithCommand:(NSString*)cmd {
  if (curState != MOSSimulatorStatePaused) return NO;
  if (![self sendCommandToSimulatorDebugger:cmd]) return 0;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self willChangeValueForKey:@"simulatorState"];
    curState = MOSSimulatorStateRunning;
    [self didChangeValueForKey:@"simulatorState"];
  });
  
  /* Watch for the next interruption. Pipe read operations will fail on
   * process death, so this will never lock forever. */
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
    NSString *temp;
    
    do {
      temp = [[fromSim fileHandleForReading] readLine];
      if (isSimDead) break;
      if (![temp isEqual:@"debug? "])
        MOSSimLog(simTask, @"Error! %@", temp);
    } while (![temp isEqual:@"debug? "]);
    
    if (!isSimDead) {
      [[toSim fileHandleForWriting] writeString:@"\n"];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [self willChangeValueForKey:@"simulatorState"];
        curState = MOSSimulatorStatePaused;
        [self didChangeValueForKey:@"simulatorState"];
      });
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
  NSString *com;
  
  if (curState != MOSSimulatorStatePaused) return nil;
  
  com = [NSString stringWithFormat:@"u %d %d", loc, cnt];
  if (![self sendCommandToSimulatorDebugger:com]) return nil;
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


+ (NSSet *)keyPathsForValuesAffectingSimulatorRunning {
  return [NSSet setWithObjects:@"simulatorState", nil];
}


- (MOSSimulatorState)simulatorState {
  if (isSimDead)
    return MOSSimulatorStateDead;
  return curState;
}


- (BOOL)isSimulatorRunning {
  if (isSimDead)
    return YES;
  return curState == MOSSimulatorStateRunning;
}


@end
