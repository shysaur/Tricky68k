//
//  MOSSimDumpDataSource.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 31/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimDumpDataSource.h"
#import "MOSSimulatorProxy.h"


@implementation MOSSimDumpDataSource


- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp {
  simProxy = sp;
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
    if (line == nil)
      line = [NSArray arrayWithObject:@"Error"];
  }
  result = [tv makeViewWithIdentifier:@"normalView" owner:self];
  [[result textField] setStringValue:[line firstObject]];
  return result;
}


@end
