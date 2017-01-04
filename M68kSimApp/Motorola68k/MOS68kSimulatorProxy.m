//
//  MOSSimulatorProxy.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 12/06/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOS68kSimulatorProxy.h"


#define RESPONSE_TIMEOUT dispatch_time(DISPATCH_TIME_NOW, 10000000000)
#define NSERROR_SIM(c) [MOSError errorWithDomain:MOSSimulatorErrorDomain \
  code:((c)) userInfo:nil]


NSString * const MOSSimulatorErrorDomain = @"MOSSimulatorErrorDomain";


void MOSSimLog(NSTask *proc, NSString *fmt, ...) {
  NSString *mess;
  va_list ap;
  
  va_start(ap, fmt);
  mess = [[NSString alloc] initWithFormat:fmt arguments:ap];
  NSLog(@"Simulator PID %d: %@", [proc processIdentifier], mess);
  va_end(ap);
}


@interface MOS68kSimulatorProxy ()

@property (atomic) NSError *lastErrorOnSimReenter;
@property (atomic) NSInteger lastSimReenterReason;

@end


@implementation MOS68kSimulatorProxy


- (instancetype)initWithExecutableURL:(NSURL*)url error:(NSError **)err {
  NSArray *args, *resp;
  NSError *tmpe;
  __weak MOS68kSimulatorProxy *weakSelf;
  __strong NSTask *strongTask;
  dispatch_semaphore_t ttyOpenSem;
  int i;
  
  if (err) *err = nil;
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
  [simTask setStandardError:fromSim];
  
  curState = MOSSimulatorStatePaused;
  [simTask launch];
  
  strongTask = simTask;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    __strong MOS68kSimulatorProxy *strongSelf;
    
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
    if (err) *err = NSERROR_SIM(MOSSimulatorErrorPipeOpeningFailure);
    [self kill];
    return self;
  }
  
  resp = [self receiveResponseWithoutCommandWithError:&tmpe restarting:NO];
  if (!resp) {
    if (err) *err = NSERROR_SIM(MOSSimulatorErrorTimeout);
    MOSSimLog(simTask, @"initial prompt timeout!");
    [self kill];
  } else if (tmpe || [resp count]) {
    if (tmpe && err) *err = tmpe;
    if ([resp count])
      MOSSimLog(simTask, @"initial response opening %@: %@", url, resp);
    [self kill];
  }
  
  enteredDebugger = dispatch_semaphore_create(0);
  waitingForDebugger = dispatch_semaphore_create(0);
  
  return self;
}


- (NSURL*)simulatorURL {
  NSBundle *cb;
  
  cb = [NSBundle bundleForClass:[self class]];
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
   
   
- (BOOL)sendCommandWithoutResponse:(NSString*)com error:(NSError **)err {
  dispatch_semaphore_t complete;
  
  complete = dispatch_semaphore_create(0);
  dispatch_async(sendQueue, ^{
    [[toSim fileHandleForWriting] writeLine:com];
    dispatch_semaphore_signal(complete);
  });
  
  if (dispatch_semaphore_wait(complete, RESPONSE_TIMEOUT)) {
    if (err) *err = NSERROR_SIM(MOSSimulatorErrorTimeout);
    [self kill];
    return NO;
  }
  return YES;
}


- (NSArray *)receiveResponseWithoutCommandWithError:(NSError **)err restarting:(BOOL)s  {
  NSMutableArray __block *res;
  NSError __block *simerr;
  dispatch_semaphore_t complete;
  
  if (err) *err = nil;
  
  complete = dispatch_semaphore_create(0);
  res = [NSMutableArray array];
  dispatch_async(receiveQueue, ^{
    NSString *tmp;
    NSString *prompt = s ? @"continuing." : @"debug? ";
    BOOL first = YES;
    
    tmp = [[fromSim fileHandleForReading] readLine];
    while (tmp && ![tmp isEqual:prompt]) {
      if (first && [tmp hasPrefix:@"error! "])
        simerr = [self errorFromLine:tmp];
      else
        [res addObject:tmp];
      tmp = [[fromSim fileHandleForReading] readLine];
      first = NO;
    }
    dispatch_semaphore_signal(complete);
  });
  
  if (dispatch_semaphore_wait(complete, RESPONSE_TIMEOUT)) {
    if (err) *err = NSERROR_SIM(MOSSimulatorErrorTimeout);
    [self kill];
    return nil;
  } else if (simerr)
    if (err) *err = simerr;
  
  return [res copy];
}


- (NSError *)errorFromLine:(NSString *)tmp {
  const char *str;
  int code = MOSSimulatorErrorUnknown;
  
  str = [tmp UTF8String];
  if ([tmp length] >= 7)
    sscanf(str+7, "%d", &code);
  
  if (code > 0)
    return NSERROR_SIM(code);
  return [NSError errorWithDomain:NSPOSIXErrorDomain code:-code userInfo:nil];
}


- (BOOL)enterDebuggerWithError:(NSError **)err {
  if ([self simulatorState] != MOSSimulatorStateRunning) {
    if (err) *err = NSERROR_SIM(MOSSimulatorErrorWrongState);
    return NO;
  }
  if (err) *err = nil;
  
  if (!dispatch_semaphore_wait(enteredDebugger, DISPATCH_TIME_NOW))
    goto done;
  
  dispatch_semaphore_signal(waitingForDebugger);
  [simTask interrupt];
  
  if (dispatch_semaphore_wait(enteredDebugger, RESPONSE_TIMEOUT)) {
    if (err) *err = NSERROR_SIM(MOSSimulatorErrorTimeout);
    [self kill];
    return NO;
  }
  
done:
  [self finishTransitionIntoDebuggerWithError:err setProperty:NO];
  return YES;
}


- (BOOL)exitDebuggerWithCommand:(NSString *)com error:(NSError **)err {
  NSError *tmpe;
  
  if ([self simulatorState] != MOSSimulatorStatePaused) {
    if (err) *err = NSERROR_SIM(MOSSimulatorErrorWrongState);
    return NO;
  }
  
  if (![self sendCommandWithoutResponse:com error:&tmpe]) {
    if (err) *err = tmpe;
    return NO;
  }
  if (![self receiveResponseWithoutCommandWithError:&tmpe restarting:YES]) {
    if (err) *err = tmpe;
    return NO;
  }

  dispatch_async(receiveQueue, ^{
    NSError *reenterError;
    NSString *tmp;
    BOOL first = YES;
    NSInteger reentReas = 0;
    
    tmp = [[fromSim fileHandleForReading] readLine];
    while (tmp && ![tmp isEqual:@"debug? "]) {
      if (first && [tmp hasPrefix:@"error! "])
        reenterError = [self errorFromLine:tmp];
      else if (first && [tmp hasPrefix:@"reason. "])
        sscanf([tmp UTF8String]+8, "%ld", &reentReas);
      else
        MOSSimLog(simTask, @"received %@ on debugger reenter", tmp);
      tmp = [[fromSim fileHandleForReading] readLine];
      first = NO;
    }
    if (!tmp) return; /* EOF => sim dead */
    
    self.lastErrorOnSimReenter = reenterError;
    self.lastSimReenterReason = reentReas;
    dispatch_semaphore_signal(enteredDebugger);
    
    if (dispatch_semaphore_wait(waitingForDebugger, DISPATCH_TIME_NOW)) {
      /* Nobody is waiting for the enteredDebugger signal. */
      dispatch_async(dispatch_get_main_queue(), ^{
        if (!dispatch_semaphore_wait(enteredDebugger, DISPATCH_TIME_NOW)) {
          /* Nobody else has acknowledge entrance into the debugger, so we
           * do it ourselves. */
          if ([self simulatorState] != MOSSimulatorStatePaused)
            [self finishTransitionIntoDebuggerWithError:nil setProperty:YES];
        }
      });
    }
  });
  
  [self setSimulatorState:MOSSimulatorStateRunning];
  return YES;
}


- (BOOL)finishTransitionIntoDebuggerWithError:(NSError **)err setProperty:(BOOL)sp  {
  if (err)
    *err = self.lastErrorOnSimReenter;
  if (sp)
    _lastSimulationException = self.lastErrorOnSimReenter;
  else
    _lastSimulationException = nil;
  [self setSimulatorState:MOSSimulatorStatePaused];
  return !!self.lastErrorOnSimReenter;
}


- (NSArray*)sendCommandToDebugger:(NSString *)com error:(NSError **)err {
  BOOL hasToRestart;
  NSArray *res;
  NSError *tmpe;
  
  if ([self simulatorState] == MOSSimulatorStateRunning) {
    hasToRestart = YES;
    [self enterDebuggerWithError:&tmpe];
    if (tmpe) {
      MOSSimLog(simTask, @"-sendCommandToDebugger:error: error during "
        "transition to debug mode: %@", tmpe);
      if (err) *err = tmpe;
      return nil;
    } else if (self.lastSimReenterReason != 0) {
      /* A breakpoint hit, a step ended, or something like that happened on
       * the simulator state, so we want to stay paused afterwards. */
      hasToRestart = NO;
    }
  } else if ([self simulatorState] == MOSSimulatorStatePaused) {
    hasToRestart = NO;
  } else {
    if (err) *err = NSERROR_SIM(MOSSimulatorErrorBrokenConnection);
    return nil;
  }
  
  if (![self sendCommandWithoutResponse:com error:&tmpe]) {
    if (err) *err = tmpe;
    return nil;
  }
  res = [self receiveResponseWithoutCommandWithError:&tmpe restarting:NO];
  if (err) *err = tmpe;
  
  if (hasToRestart) {
    if (![self exitDebuggerWithCommand:@"c" error:&tmpe]) {
      MOSSimLog(simTask, @"-sendCommandToDebugger:error: can't reenter "
        "running mode! %@", tmpe);
      [self kill];
    }
  }
  return res;
}


- (NSError*)lastSimulationException {
  if ([self simulatorState] == MOSSimulatorStateRunning)
    return nil;
  return _lastSimulationException;
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
