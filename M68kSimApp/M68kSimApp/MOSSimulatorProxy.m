//
//  MOSSimulatorProxy.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MOSNamedPipe.h"
#import "MOSSimulatorProxy.h"
#import "NSFileHandle+Strings.h"


NSString * const MOS68kRegisterD0    = @"D0";
NSString * const MOS68kRegisterD1    = @"D1";
NSString * const MOS68kRegisterD2    = @"D2";
NSString * const MOS68kRegisterD3    = @"D3";
NSString * const MOS68kRegisterD4    = @"D4";
NSString * const MOS68kRegisterD5    = @"D5";
NSString * const MOS68kRegisterD6    = @"D6";
NSString * const MOS68kRegisterD7    = @"D7";
NSString * const MOS68kRegisterA0    = @"A0";
NSString * const MOS68kRegisterA1    = @"A1";
NSString * const MOS68kRegisterA2    = @"A2";
NSString * const MOS68kRegisterA3    = @"A3";
NSString * const MOS68kRegisterA4    = @"A4";
NSString * const MOS68kRegisterA5    = @"A5";
NSString * const MOS68kRegisterA6    = @"A6";
NSString * const MOS68kRegisterSP    = @"SP";
NSString * const MOS68kRegisterPC    = @"PC";
NSString * const MOS68kRegisterSR    = @"SR";
NSString * const MOS68kRegisterUSP   = @"USP";
NSString * const MOS68kRegisterISP   = @"ISP";
NSString * const MOS68kRegisterMSP   = @"MSP";
NSString * const MOS68kRegisterSFC   = @"SFC";
NSString * const MOS68kRegisterDFC   = @"DFC";
NSString * const MOS68kRegisterVBR   = @"VBR";
NSString * const MOS68kRegisterCACR  = @"CACR";
NSString * const MOS68kRegisterCAAR  = @"CAAR";


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
  __weak MOSSimulatorProxy *weakSelf;
  __strong NSTask *strongTask;
  
  self = [super init];
  weakSelf = self;
  
  simQueue = dispatch_queue_create("com.danielecattaneo.m68ksimqueue", NULL);
  
  toSim = [[NSPipe alloc] init];
  fromSim = [[NSPipe alloc] init];
  toSimTty = [[MOSNamedPipe alloc] init];
  fromSimTty = [[MOSNamedPipe alloc] init];
  args = @[@"-B", @"-d", @"-l", [url path],
           @"-I", @"tty", @"0xFFE000", [[toSimTty pipeURL] path], [[fromSimTty pipeURL] path]];
  
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
  
  [toSimTty fileHandleForWriting];
  [fromSimTty fileHandleForReading];
  
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
      strongSelf->isSimDead = YES;
      dispatch_async(dispatch_get_main_queue(), ^{
        [strongSelf changeSimulatorStatusTo:MOSSimulatorStateDead];
      });
    }
  });
  
  return self;
}


- (BOOL)sendCommandToSimulatorDebugger:(NSString *)com {
  NSString *dbgPrmpt;
  
  if (curState != MOSSimulatorStatePaused || isSimDead) return NO;
  
  dbgPrmpt = [[fromSim fileHandleForReading] readLine];
  if (isSimDead) return NO;
  
  if (![dbgPrmpt isEqual:@"debug? "]) {
    MOSSimLog(simTask, @"Can't send command %@. Read %@ instead of prompt.", com, dbgPrmpt);
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self changeSimulatorStatusTo:MOSSimulatorStateUnknown];
    });
    return NO;
  }
  
  [[toSim fileHandleForWriting] writeLine:com];
  return YES;
}


- (NSArray*)getSimulatorResponse {
  NSString *tmp;
  NSMutableArray *res;
  
  res = [NSMutableArray array];
  tmp = [[fromSim fileHandleForReading] readLine];
  while (![tmp isEqual:@"debug? "]) {
    [res addObject:tmp];
    tmp = [[fromSim fileHandleForReading] readLine];
  }
  [[toSim fileHandleForWriting] writeLine:@""];
  return [res copy];
}


- (NSArray*)getSimulatorResponseWithLength:(int)c {
  int i;
  NSString *tmp;
  NSMutableArray *res;
  
  res = [NSMutableArray array];
  for (i=0; i<c; i++) {
    tmp = [[fromSim fileHandleForReading] readLine];
    if (!tmp) break; /* eof */
    if ([tmp isEqual:@"debug? "]) {
      if (i==1)
        MOSSimLog(simTask, @"Error! %@", res);
      else
        MOSSimLog(simTask, @"Response incomplete. %d lines expected. %@", c, res);
      [[toSim fileHandleForWriting] writeLine:@""];
      break;
    }
    [res addObject:tmp];
  }
  return [res copy];
}


- (BOOL)runWithCommand:(NSString*)cmd {
  
  if (curState != MOSSimulatorStatePaused || isSimDead) return NO;
  if (![self sendCommandToSimulatorDebugger:cmd]) return NO;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self changeSimulatorStatusTo:MOSSimulatorStateRunning];
  });
  
  /* Watch for the next interruption. Pipe read operations will fail on
   * process death, so this will never lock forever. */
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
    NSString *temp;
    
    do {
      temp = [[fromSim fileHandleForReading] readLine];
      if (isSimDead || !temp) break; /* eof <=> simulator died */
      
      if (![temp isEqual:@"debug? "])
        MOSSimLog(simTask, @"Error! %@", temp);
    } while (![temp isEqual:@"debug? "]);
    
    if (!isSimDead && temp) {
      [[toSim fileHandleForWriting] writeLine:@""];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [self changeSimulatorStatusTo:MOSSimulatorStatePaused];
      });
    }
  });
  
  return YES;
}


- (void)changeSimulatorStatusTo:(MOSSimulatorState)news {
  if (curState == news) return;
  [self willChangeValueForKey:@"simulatorState"];
  curState = news;
  [self didChangeValueForKey:@"simulatorState"];
}


- (BOOL)run {
  return [self runWithCommand:@"c"];
}


- (BOOL)stop {
  if (curState != MOSSimulatorStateRunning || isSimDead) return NO;
  [simTask interrupt];
  return YES;
}


- (NSArray*)disassemble:(int)cnt instructionsFromLocation:(uint32_t)loc {
  NSString *com;
  NSArray __block *res;
  
  if (curState != MOSSimulatorStatePaused || isSimDead) return nil;
  
  com = [NSString stringWithFormat:@"u %d %d", loc, cnt];
  dispatch_sync(simQueue, ^{
    if ([self sendCommandToSimulatorDebugger:com])
      res = [self getSimulatorResponseWithLength:ABS(cnt)];
  });
  return res;
}


- (NSArray*)dump:(int)cnt linesFromLocation:(uint32_t)loc {
  NSString *com;
  NSArray __block *res;
  
  if (curState != MOSSimulatorStatePaused || isSimDead) return nil;
  
  com = [NSString stringWithFormat:@"d %d %d", loc, cnt];
  dispatch_sync(simQueue, ^{
    if ([self sendCommandToSimulatorDebugger:com])
      res = [self getSimulatorResponseWithLength:cnt];
  });
  return res;
}


- (NSData*)rawDumpFromLocation:(uint32_t)loc withSize:(uint32_t)size {
  NSArray *lines;
  NSMutableData *res;
  const char *line, *linep;
  int i, j, c, t;
  uint8_t decLine[16];
  
  c = (size+15) / 16;
  lines = [self dump:c linesFromLocation:loc];
  res = [NSMutableData data];
  for (i=0; i<c; i++) {
    line = [[lines objectAtIndex:i] UTF8String];
    linep = line + 10;
    for (j=0; j<16; j++) {
      t = *(linep++);
      t = t > '9' ? t - 'A' + 10 : t - '0';
      decLine[j] = t * 16;
      t = *(linep++);
      t = t > '9' ? t - 'A' + 10 : t - '0';
      decLine[j] += t;
      linep++;
    }
    [res appendBytes:decLine length:size>16 ? 16 : size];
    size -= 16;
  }
  
  return [res copy];
}


- (NSDictionary*)registerDump {
  NSMutableDictionary *res;
  NSArray __block *list;
  NSString *obj, *rego;
  NSNumber *valo;
  const char *tmp;
  char reg[10], pad[10];
  uint32_t val;
  
  dispatch_sync(simQueue, ^{
    if ([self sendCommandToSimulatorDebugger:@"v"])
      list = [self getSimulatorResponse];
  });
  
  res = [NSMutableDictionary dictionary];
  for (obj in list) {
    tmp = [obj UTF8String];
    sscanf(tmp, "%s%s%X", reg, pad, &val);
    rego = [NSString stringWithUTF8String:reg];
    valo = [NSNumber numberWithUnsignedLong:val];
    [res setObject:valo forKey:rego];
  }
  return [res copy];
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


+ (NSSet *)keyPathsForValuesAffectingSimulatorDead {
  return [NSSet setWithObjects:@"simulatorState", nil];
}


- (MOSSimulatorState)simulatorState {
  return curState;
}


- (BOOL)isSimulatorRunning {
  return curState == MOSSimulatorStateRunning;
}


- (BOOL)isSimulatorDead {
  return curState == MOSSimulatorStateDead;
}


- (NSFileHandle*)teletypeOutput {
  return [toSimTty fileHandleForWriting];
}


- (NSFileHandle*)teletypeInput {
  return [fromSimTty fileHandleForReading];
}


- (void)dealloc {
  [self kill];
}


@end
