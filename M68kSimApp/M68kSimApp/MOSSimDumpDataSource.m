//
//  MOSSimDumpDataSource.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 31/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import "MOSSimDumpDataSource.h"
#import "MOSSimulator.h"
#import "MOS68kSimulator.h"


@implementation MOSSimDumpDataSource


- (void)setSimulatorProxy:(MOSSimulator*)sp {
  NSUInteger pc;
  NSInteger rows;
  NSRect visibleRect;
  
  [super setSimulatorProxy:sp];
  pc = [[[sp registerDump] objectForKey:MOS68kRegisterPC] unsignedIntegerValue];
  
  visibleRect = [tableView visibleRect];
  rows = [tableView rowsInRect:visibleRect].length;
  [tableView scrollRowToVisible:pc/16+rows*2/3];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return 0x1000000 / 16;
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
