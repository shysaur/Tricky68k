//
//  MOSSimStackDumpDataSource.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 02/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSSimStackDumpDataSource.h"
#import "MOS68kSimulator.h"


@implementation MOSSimStackDumpDataSource


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return 0x1000000 / 16;
}


- (NSView *)tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tc row:(NSInteger)row {
  uint32_t addr;
  uint8_t *dump;
  NSData *data;
  NSString *line;
  NSDictionary *regs;
  id result;
  
  if ([simProxy simulatorState] != MOSSimulatorStatePaused) {
    line = @"";
  } else {
    regs = [simProxy registerDump];
    addr = [[regs objectForKey:MOS68kRegisterSP] unsignedIntValue];
    addr += row * 4;
    data = [simProxy rawDumpFromLocation:addr withSize:4];
    if (data) {
      dump = (uint8_t*)[data bytes];
      line = [NSString stringWithFormat:@"%08X: %02X%02X %02X%02X",
        addr, dump[0], dump[1], dump[2], dump[3]];
    } else {
      line = @"";
    }
  }
  result = [tv makeViewWithIdentifier:@"normalView" owner:self];
  [[result textField] setFont:[self defaultMonospacedFont]];
  [[result textField] setStringValue:line];
  return result;
}


@end
