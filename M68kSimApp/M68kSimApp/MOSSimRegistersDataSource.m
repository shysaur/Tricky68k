//
//  MOSSimRegistersDataSource.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 01/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSSimRegistersDataSource.h"
#import "MOSSimulator.h"
#import "MOSSimulatorPresentation.h"


@implementation MOSSimRegistersDataSource


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  NSArray *rfi;
  
  rfi = [[simProxy presentation] registerFileInterpretation];
  return [rfi count];
}


- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
  NSArray *rfi;
  
  rfi = [[simProxy presentation] registerFileInterpretation];
  return [[rfi objectAtIndex:row] isKindOfClass:[NSString class]];
}


- (NSView *)tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tc row:(NSInteger)row {
  NSArray *rfi;
  id rowobj;
  id result;
  
  rfi = [[simProxy presentation] registerFileInterpretation];
  rowobj = [rfi objectAtIndex:row];
  if ([rowobj isKindOfClass:[NSString class]]) {
    result = [tv makeViewWithIdentifier:@"headerView" owner:self];
    [[result textField] setStringValue:rowobj];
  } else {
    if ([[tc identifier] isEqual:@"nameColumn"]) {
      result = [tv makeViewWithIdentifier:@"nameView" owner:self];
      [[result textField] setFont:[self defaultMonospacedFont]];
      [[result textField] setStringValue:[rowobj objectForKey:@"label"]];
    } else {
      result = [tv makeViewWithIdentifier:@"valueView" owner:self];
      [[result textField] setFont:[self defaultMonospacedFont]];
      [[result textField] setStringValue:[rowobj objectForKey:@"string"]];
    }
  }
  return result;
}


@end
