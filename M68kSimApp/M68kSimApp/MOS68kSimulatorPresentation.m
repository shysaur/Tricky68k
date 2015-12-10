//
//  MOS68kSimulatorPresentation.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 10/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOS68kSimulatorPresentation.h"
#import "MOS68kSimulator.h"


static void MOSAddRegisterFileInterpSection(NSMutableArray *work, BOOL small,
  NSString *head, NSDictionary *regsCache, NSArray *regs) {
  NSString *t;
  uint32_t regval;
  NSString *fn;
  
  [work addObject:head];
  for (t in regs) {
    if (regsCache) {
      regval = [[regsCache objectForKey:t] unsignedIntValue];
      fn = [NSString stringWithFormat:small ? @"%04X" : @"%08X", regval];
    } else
      fn = @"";
    [work addObject:@{@"label": t, @"string": fn}];
  }
}


@implementation MOS68kSimulatorPresentation


- (instancetype)initWithSimulator:(MOS68kSimulator *)s {
  self = [super initWithSimulator:s];
  sim = s;
  return self;
}


- (NSNumber *)programCounter {
  NSDictionary *regs;
  
  if ([sim simulatorState] != MOSSimulatorStatePaused)
    return nil;
  
  regs = [sim registerDump];
  return [regs objectForKey:MOS68kRegisterPC];
}


- (NSNumber *)stackPointer {
  NSDictionary *regs;
  
  if ([sim simulatorState] != MOSSimulatorStatePaused)
    return nil;
  
  regs = [sim registerDump];
  return [regs objectForKey:MOS68kRegisterSP];
}


- (NSNumber *)statusRegister {
  NSDictionary *regs;
  
  if ([sim simulatorState] != MOSSimulatorStatePaused)
    return nil;
  
  regs = [sim registerDump];
  return [regs objectForKey:MOS68kRegisterSR];
}


- (NSString *)statusRegisterInterpretation {
  NSDictionary *regdump;
  uint32_t flags;
  int x, n, z, v, c;
  
  if ([sim simulatorState] != MOSSimulatorStatePaused)
    return @"";
  
  regdump = [sim registerDump];
  flags = [[regdump objectForKey:MOS68kRegisterSR] unsignedIntValue];
  x = (flags & 0b10000) >> 4;
  n = (flags & 0b1000) >> 3;
  z = (flags & 0b100) >> 2;
  v = (flags & 0b10) >> 1;
  c = (flags & 0b1);
  return [NSString stringWithFormat:@"X:%d N:%d Z:%d V:%d C:%d", x, n, z, v, c];
}


- (NSArray *)registerFileInterpretation {
  NSString *sr, *dr, *ar;
  NSMutableArray *work;
  BOOL empty;
  
  empty = ([sim simulatorState] != MOSSimulatorStatePaused);
  
  if (!empty && regsCache != [sim registerDump]) {
    regsCache = [sim registerDump];
    regFileCache = nil;
  } else if (empty && regsCache) {
    regsCache = nil;
    regFileCache = nil;
  }
  
  if (!regFileCache) {
    sr = NSLocalizedString(@"Status Register", @"Register table header for SR");
    dr = NSLocalizedString(@"Data Registers", @"Register table header for Dx");
    ar = NSLocalizedString(@"Address Registers", @"Register table header for Ax, SP, PC");
    work = [NSMutableArray array];
    
    MOSAddRegisterFileInterpSection(work, YES, sr, regsCache, @[@"SR"]);
    MOSAddRegisterFileInterpSection(work, NO, dr, regsCache, @[@"D0",@"D1",
      @"D2",@"D3",@"D4",@"D5",@"D6",@"D7"]);
    MOSAddRegisterFileInterpSection(work, NO, ar, regsCache, @[@"A0",@"A1",
      @"A2",@"A3",@"A4",@"A5",@"A6",@"SP",@"PC"]);
    regFileCache = [work copy];
  }
  return regFileCache;
}


@end
