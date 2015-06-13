//
//  MOSSimulatorProxy.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 12/06/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorProxy.h"
#import "MOSNamedPipe.h"
#import "NSFileHandle+Strings.h"


#define RESPONSE_TIMEOUT dispatch_time(DISPATCH_TIME_NOW, 1000000000)


void MOSSimLog(NSTask *proc, NSString *fmt, ...) {
  NSString *mess;
  va_list ap;
  
  va_start(ap, fmt);
  mess = [[NSString alloc] initWithFormat:fmt arguments:ap];
  NSLog(@"Simulator PID %d: %@", [proc processIdentifier], mess);
  va_end(ap);
}


@implementation MOSSimulatorProxy


- (instancetype)initWithExecutableURL:(NSURL*)url {
  NSArray *args, *resp;
  __weak MOSSimulatorProxy *weakSelf;
  __strong NSTask *strongTask;
  dispatch_semaphore_t ttyOpenSem;
  int i;
  
  self = [super init];
  if (!self) return nil;
  
  weakSelf = self;
  exec = url;
  sendQueue = dispatch_queue_create("com.danielecattaneo.m68ksimqueues.send", NULL);
  receiveQueue = dispatch_queue_create("com.danielecattaneo.m68ksimqueues.receive", NULL);
  
  toSim = [[NSPipe alloc] init];
  fromSim = [[NSPipe alloc] init];
  toSimTty = [[MOSNamedPipe alloc] init];
  fromSimTty = [[MOSNamedPipe alloc] init];
  args = @[@"-B", @"-d",  @"-I", @"tty", @"0xFFE000",
           [[toSimTty pipeURL] path], [[fromSimTty pipeURL] path],
           @"-l", [url path]];
  
  simTask = [[NSTask alloc] init];
  [simTask setLaunchPath:[[self simulatorURL] path]];
  [simTask setArguments:args];
  [simTask setStandardInput:toSim];
  [simTask setStandardOutput:fromSim];
  
  curState = MOSSimulatorStatePaused;
  [simTask launch];
  
  strongTask = simTask;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    __strong MOSSimulatorProxy *strongSelf;
    
    [strongTask waitUntilExit];
    /* We don't want this block to retain the proxy, otherwise we can't kill
     * the simulator on dealloc. We won't be able to kill it when a command
     * is in progress, though (so it won't work when the simulator is running,
     * for example). */
    strongSelf = weakSelf;
    
    if (strongSelf) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if ([strongSelf simulatorState] != MOSSimulatorStateDead)
          [strongSelf setSimulatorState:MOSSimulatorStateDead];
      });
    }
  });
  
  ttyOpenSem = dispatch_semaphore_create(0);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    while (![fromSimTty fileHandleForReading]);
    dispatch_semaphore_signal(ttyOpenSem);
  });
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    while (![toSimTty fileHandleForWriting]);
    dispatch_semaphore_signal(ttyOpenSem);
  });
  dispatch_async(receiveQueue, ^{
    while (![fromSim fileHandleForReading]);
    dispatch_semaphore_signal(ttyOpenSem);
  });
  dispatch_async(sendQueue, ^{
    while (![toSim fileHandleForWriting]);
    dispatch_semaphore_signal(ttyOpenSem);
  });
  
  for (i=0; i<4; i++) {
    if (dispatch_semaphore_wait(ttyOpenSem, RESPONSE_TIMEOUT))
      break;
  }
  if (i != 4) {
    MOSSimLog(simTask, @"can't open pipes");
    [self kill];
    return self;
  }
  
  resp = [self receiveResponseWithoutCommand];
  if (!resp) {
    MOSSimLog(simTask, @"initial prompt timeout!");
    [self kill];
  } else if ([resp count]) {
    MOSSimLog(simTask, @"error opening %@: @%", url, resp);
    [self kill];
  }
  
  enteredDebugger = dispatch_semaphore_create(0);
  waitingForDebugger = dispatch_semaphore_create(0);
  
  return self;
}


- (NSURL*)simulatorURL {
  NSBundle *cb;
  
  cb = [NSBundle mainBundle];
  return [cb URLForAuxiliaryExecutable:@"m68ksim"];
}


- (NSURL*)executableURL {
  return exec;
}


- (MOSSimulatorState)simulatorState {
  return curState;
}


- (void)setSimulatorState:(MOSSimulatorState)ns {
  curState = ns;
}
   
   
- (BOOL)sendCommandWithoutResponse:(NSString*)com {
  dispatch_semaphore_t complete;
  
  complete = dispatch_semaphore_create(0);
  dispatch_async(sendQueue, ^{
    [[toSim fileHandleForWriting] writeLine:com];
    dispatch_semaphore_signal(complete);
  });
  
  if (dispatch_semaphore_wait(complete, RESPONSE_TIMEOUT)) {
    MOSSimLog(simTask, @"debugger command send timeout!");
    return NO;
  }
  return YES;
}


- (NSArray*)receiveResponseWithoutCommand {
  NSMutableArray __block *res;
  dispatch_semaphore_t complete;
  
  complete = dispatch_semaphore_create(0);
  res = [NSMutableArray array];
  dispatch_async(receiveQueue, ^{
    NSString *tmp;
    
    tmp = [[fromSim fileHandleForReading] readLine];
    while (tmp && ![tmp isEqual:@"debug? "]) {
      [res addObject:tmp];
      tmp = [[fromSim fileHandleForReading] readLine];
    }
    dispatch_semaphore_signal(complete);
  });
  
  if (dispatch_semaphore_wait(complete, RESPONSE_TIMEOUT)) {
    MOSSimLog(simTask, @"debugger response timeout!");
    return nil;
  }
  
  return [res copy];
}


- (void)enterDebugger {
  if ([self simulatorState] != MOSSimulatorStateRunning)
    return;
  if (!dispatch_semaphore_wait(enteredDebugger, DISPATCH_TIME_NOW)) {
    [self setSimulatorState:MOSSimulatorStatePaused];
    return;
  }
  
  dispatch_semaphore_signal(waitingForDebugger);
  [simTask interrupt];
  
  if (dispatch_semaphore_wait(enteredDebugger, RESPONSE_TIMEOUT)) {
    MOSSimLog(simTask, @"task did not reenter the debugger!!");
    [simTask terminate];
    return;
  }
  
  [self setSimulatorState:MOSSimulatorStatePaused];
}


- (void)exitDebuggerWithCommand:(NSString *)com {
  if ([self simulatorState] != MOSSimulatorStatePaused)
    return;
  [self sendCommandWithoutResponse:com];
  [self setSimulatorState:MOSSimulatorStateRunning];
  
  dispatch_async(receiveQueue, ^{
    NSString *tmp;
    
    tmp = [[fromSim fileHandleForReading] readLine];
    while (tmp && ![tmp isEqual:@"debug? "]) {
      MOSSimLog(simTask, @"received %@ on debugger reenter", tmp);
      tmp = [[fromSim fileHandleForReading] readLine];
    }
    if (dispatch_semaphore_wait(waitingForDebugger, DISPATCH_TIME_NOW)) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if ([self simulatorState] != MOSSimulatorStatePaused) {
          [self setSimulatorState:MOSSimulatorStatePaused];
          dispatch_semaphore_wait(enteredDebugger, DISPATCH_TIME_FOREVER);
        }
      });
    }
    dispatch_semaphore_signal(enteredDebugger);
  });
}


- (NSArray*)sendCommandToDebugger:(NSString *)com {
  BOOL hasToRestart;
  NSArray *res;
  
  if ([self simulatorState] == MOSSimulatorStateRunning) {
    hasToRestart = YES;
    [self enterDebugger];
  } else if ([self simulatorState] == MOSSimulatorStatePaused)
    hasToRestart = NO;
  else
    return nil;
  
  if (![self sendCommandWithoutResponse:com])
    return nil;
  res = [self receiveResponseWithoutCommand];
  
  if (hasToRestart)
    [self exitDebuggerWithCommand:@"c"];
  return res;
}


- (NSFileHandle*)teletypeOutput {
  return [toSimTty fileHandleForWriting];
}


- (NSFileHandle*)teletypeInput {
  return [fromSimTty fileHandleForReading];
}


- (void)dealloc {
  [simTask terminate];
}


- (void)kill {
  [simTask terminate];
  [self setSimulatorState:MOSSimulatorStateDead];
}


@end
