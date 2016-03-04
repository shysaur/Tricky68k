//
//  MOSSimDumpDataSource.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 31/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import "MOSSimDumpDataSource.h"
#import "MOSSimulator.h"
#import "MOSSimulatorPresentation.h"


@implementation MOSSimDumpDataSource


+ (void)load {
  NSUserDefaults *ud;
  
  ud = [NSUserDefaults standardUserDefaults];
  [ud registerDefaults:@{
    @"RAMDumpSize": @16384
  }];
}


- (instancetype)init {
  NSUInteger maxKb;
  
  self = [super init];
  
  maxKb = [[NSUserDefaults standardUserDefaults] integerForKey:@"RAMDumpSize"];
  maxLines = maxKb * 1024 / 16;
  
  return self;
}


- (void)setSimulatorProxy:(MOSSimulator*)sp {
  NSUInteger pc, dest;
  NSInteger rows;
  NSRect visibleRect;
  MOSSimulatorPresentation *pres;
  
  [super setSimulatorProxy:sp];
  pres = [sp presentation];
  pc = [[pres programCounter] unsignedIntegerValue];
  
  visibleRect = [tableView visibleRect];
  rows = [tableView rowsInRect:visibleRect].length;
  dest = MIN(pc/16+rows*2/3, maxLines-1);
  [tableView scrollRowToVisible:dest];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return maxLines;
}


- (NSView *)tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tc row:(NSInteger)row {
  uint32_t addr;
  NSArray *line;
  id result;
  
  if ([simProxy simulatorState] != MOSSimulatorStatePaused) {
    line = [NSArray arrayWithObject:@""];
  } else {
    addr = (uint32_t)(row * 16);
    line = [simProxy dump:1 linesFromLocation:addr];
    if (!line)
      line = [NSArray arrayWithObject:@""];
  }
  result = [tv makeViewWithIdentifier:@"normalView" owner:self];
  [[result textField] setFont:[self defaultMonospacedFont]];
  [[result textField] setStringValue:[line firstObject]];
  return result;
}


@end
