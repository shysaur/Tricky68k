//
//  MOSSimRegistersDataSource.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 01/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimRegistersDataSource.h"
#import "MOSSimulatorProxy.h"


const BOOL isRowHeader[] = {
  YES, NO,
  YES, NO,NO,NO,NO,NO,NO,NO,NO,
  YES, NO,NO,NO,NO,NO,NO,NO,NO,NO
};


@implementation MOSSimRegistersDataSource


- init {
  self = [super init];
  rows = @[
    @"Status Register",   @"SR",
    @"Data Registers",    @"D0",@"D1",@"D2",@"D3",@"D4",@"D5",@"D6",@"D7",
    @"Address Registers", @"A0",@"A1",@"A2",@"A3",@"A4",@"A5",@"A6",@"SP",@"PC"];
  return self;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [rows count];
}


- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
  return isRowHeader[row];
}


- (NSView *)tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tc row:(NSInteger)row {
  NSDictionary *dump;
  NSString *line;
  NSNumber *value;
  id result;
  
  if (isRowHeader[row]) {
    result = [tv makeViewWithIdentifier:@"headerView" owner:self];
    [[result textField] setStringValue:[rows objectAtIndex:row]];
  } else {
    if ([[tc identifier] isEqual:@"nameColumn"]) {
      result = [tv makeViewWithIdentifier:@"nameView" owner:self];
      [[result textField] setFont:[self defaultMonospacedFont]];
      [[result textField] setStringValue:[rows objectAtIndex:row]];
    } else {
      result = [tv makeViewWithIdentifier:@"valueView" owner:self];
      if ([simProxy simulatorState] != MOSSimulatorStatePaused) {
        line = @"";
      } else {
        dump = [simProxy registerDump];
        value = [dump valueForKey:[rows objectAtIndex:row]];
        if ([[rows objectAtIndex:row] isEqual:MOS68kRegisterSR])
          line = [NSString stringWithFormat:@"%04X", [value intValue]];
        else
          line = [NSString stringWithFormat:@"%08X", [value intValue]];
      }
      [[result textField] setFont:[self defaultMonospacedFont]];
      [[result textField] setStringValue:line];
    }
  }
  return result;
}


@end
