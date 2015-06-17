//
//  MOSSimulatorProxy.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>
#import "MOSSimulatorProxy.h"
#import "MOSSimulator.h"
#import "NSFileHandle+Strings.h"
#import "MOSError.h"


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


static void * SimulatorStateChanged = &SimulatorStateChanged;


@implementation MOSSimulator


+ (void)load {
  NSDictionary *userinfo, *notelf, *simissue;
  NSString *invalidex;
  
  invalidex = NSLocalizedString(@"Impossible to load this executable",
    @"Error description when the simulator can't load a file");
  simissue = @{
    NSLocalizedDescriptionKey: NSLocalizedString(@"Can't connect to the "
      "simulator", @"Description for generic simulator IPC errors"),
    NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"The "
      "simulator's process is not responding.", @"Recovery suggestion for "
      "generic simulator IPC errors (no options are given)")};
  notelf = @{
    NSLocalizedDescriptionKey: invalidex,
    NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"The file you're "
      "trying to open is not a valid Motorola 68000 32-bit big-endian "
      "executable ELF file. It has probably been made for another "
      "architecture.", @"Recovery suggestion for not opening a valid ELF")};
  
  userinfo = @{
    @(MOSSimulatorErrorTimeout): simissue,
    @(MOSSimulatorErrorPipeOpeningFailure): simissue,
    @(299): @{
      NSLocalizedDescriptionKey: NSLocalizedString(@"Segmentation fault!",
        @"Error description when the user program segmentation faults"),
      NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Your program "
        "has accessed a memory area not declared with a DS or DC directive, or "
        "a stack overflow occurred.", @"Recovery suggestion for a segmentation "
        "fault in the simulated program")},
    @(501): notelf,
    @(502): notelf,
    @(503): notelf,
    @(504): @{
      NSLocalizedDescriptionKey: NSLocalizedString(@"The entry point is "
        "missing", @"Error description when the ELF file's entry point is "
        "NULL"),
      NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"To make the "
        "entry point available, declare it as a public symbol using the "
        "\"public\" directive, or select \"Use fixed entry point\" in the "
        "assembler preferences.", @"Recovery suggestion for fixing a missing "
        "entry point")},
    @(512): @{
      NSLocalizedDescriptionKey: invalidex,
      NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"This file "
        "is a dynamic library.", @"Recovery suggestion for opening a dylib")}
  };
  
  [MOSError setUserInfoValueDictionary:userinfo forDomain:MOSSimulatorErrorDomain];
}


- initWithExecutableURL:(NSURL*)url error:(NSError **)err {
  NSFileHandle *fromSim;
  __weak MOSSimulator *weakSelf;
  NSError *tmpe;
  
  weakSelf = self = [super init];
  if (!self) return nil;
  
  proxy = [[MOSSimulatorProxy alloc] initWithExecutableURL:url error:&tmpe];
  if (err) *err = tmpe;
  
  [proxy addObserver:self forKeyPath:@"simulatorState"
    options:NSKeyValueObservingOptionInitial context:SimulatorStateChanged];
  
  fromSim = [proxy teletypeInput];
  
  if ([proxy simulatorState] != MOSSimulatorStateDead) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      MOSSimulator *strongSelf;
      void (^sendblock)(NSString *string);
      NSData *temp;
      NSString *str;
      
      temp = [fromSim readDataOfLength:1];
      while ([temp length]) {
        strongSelf = weakSelf;
        sendblock = strongSelf->ttySendBlock;
        strongSelf = nil;
        
        str = [[NSString alloc] initWithData:temp encoding:NSISOLatin1StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
          sendblock(str);
        });
        temp = [fromSim readDataOfLength:1];
      }
    });
  }
  
  return self;
}


- (NSURL*)executableURL {
  return [proxy executableURL];
}


- (BOOL)run {
  return [proxy exitDebuggerWithCommand:@"c" error:nil];
}


- (BOOL)stop {
  return [proxy enterDebuggerWithError:nil];
}


- (NSArray*)disassemble:(int)cnt instructionsFromLocation:(uint32_t)loc {
  NSString *com;

  com = [NSString stringWithFormat:@"u %d %d", loc, cnt];
  return [proxy sendCommandToDebugger:com error:nil];
}


- (NSArray*)dump:(int)cnt linesFromLocation:(uint32_t)loc {
  NSString *com;
  
  com = [NSString stringWithFormat:@"d %d %d", loc, cnt];
  return [proxy sendCommandToDebugger:com error:nil];
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
  NSArray *list;
  NSString *obj, *rego;
  NSNumber *valo;
  const char *tmp;
  char reg[10], pad[10];
  uint32_t val;
  
  if (regsCache) return regsCache;
  
  list = [proxy sendCommandToDebugger:@"v" error:nil];
  
  res = [NSMutableDictionary dictionary];
  for (obj in list) {
    tmp = [obj UTF8String];
    sscanf(tmp, "%s%s%X", reg, pad, &val);
    rego = [NSString stringWithUTF8String:reg];
    valo = [NSNumber numberWithUnsignedInt:val];
    [res setObject:valo forKey:rego];
  }
  return regsCache = [res copy];
}


- (NSArray*)breakpointList {
  NSString *obj;
  const char *data;
  NSArray *list;
  NSMutableSet *res;
  uint32_t addr;
  
  list = [proxy sendCommandToDebugger:@"p" error:nil];
  
  res = [[NSMutableSet alloc] init];
  for (obj in list) {
    data = [obj UTF8String];
    sscanf(data+3, "%X", &addr);
    [res addObject:[NSNumber numberWithUnsignedInt:addr]];
  }
  return [res copy];
}


- (void)addBreakpointAtAddress:(uint32_t)addr {
  [proxy sendCommandToDebugger:[NSString stringWithFormat:@"b 0x%X", addr] error:nil];
}


- (void)removeBreakpointAtAddress:(uint32_t)addr {
  [proxy sendCommandToDebugger:[NSString stringWithFormat:@"x 0x%X", addr] error:nil];
}


- (void)addBreakpoints:(NSSet*)addrs {
  NSNumber *addr;
  
  for (addr in addrs) {
    [self addBreakpointAtAddress:[addr unsignedIntValue]];
  }
}


- (void)removeAllBreakpoints {
  NSSet *addrs;
  NSNumber *addr;
  
  addrs = [self breakpointList];
  for (addr in addrs) {
    [self removeBreakpointAtAddress:[addr unsignedIntValue]];
  }
}


- (BOOL)stepIn {
  return [proxy exitDebuggerWithCommand:@"s" error:nil];
}


- (BOOL)stepOver {
  return [proxy exitDebuggerWithCommand:@"n" error:nil];
}


- (void)kill {
  [proxy kill];
}


- (float)clockFrequency {
  NSArray *line;
  NSString *tmp;
  long long int khz;
  
  disableNotifications = YES;
  line = [proxy sendCommandToDebugger:@"f" error:nil];
  disableNotifications = NO;
  if ([self simulatorState] != [proxy simulatorState])
    [self setSimulatorState:[proxy simulatorState]];
  
  tmp = [line firstObject];
  sscanf([tmp UTF8String], "%lld", &khz);
  if (khz < 0)
    return khz;
  return (float)khz / 1000.0;
}


+ (NSSet *)keyPathsForValuesAffectingSimulatorRunning {
  return [NSSet setWithObjects:@"simulatorState", nil];
}


+ (NSSet *)keyPathsForValuesAffectingSimulatorDead {
  return [NSSet setWithObjects:@"simulatorState", nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
  change:(NSDictionary *)change context:(void *)context {
  
  if (context == SimulatorStateChanged) {
    if (!disableNotifications)
      [self setSimulatorState:[proxy simulatorState]];
  } else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (void)setSimulatorState:(MOSSimulatorState)state {
  stateMirror = state;
  if (state == MOSSimulatorStateRunning)
    regsCache = nil;
}


- (MOSSimulatorState)simulatorState {
  return stateMirror;
}


- (BOOL)isSimulatorRunning {
  return [self simulatorState] == MOSSimulatorStateRunning;
}


- (BOOL)isSimulatorDead {
  return [self simulatorState] == MOSSimulatorStateDead;
}


- (void)setSendToTeletypeBlock:(void (^)(NSString *string))block {
  ttySendBlock = block;
}


- (void)sendToSimulator:(NSString*)string {
  NSData *data;
  
  data = [string dataUsingEncoding:NSISOLatin1StringEncoding];
  [[proxy teletypeOutput] writeData:data];
}


- (NSError *)lastSimulatorException {
  return [proxy lastSimulationException];
}


- (void)dealloc {
  [proxy removeObserver:self forKeyPath:@"simulatorState" context:SimulatorStateChanged];
}


@end
