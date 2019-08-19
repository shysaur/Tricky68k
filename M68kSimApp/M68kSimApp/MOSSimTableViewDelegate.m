//
//  MOSSimTableViewDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 05/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSSimulator.h"
#import "MOSSimTableViewDelegate.h"


static void *ReloadTableView = &ReloadTableView;


@implementation MOSSimTableViewDelegate


- (instancetype)init {
  self = [super init];
  return self;
}


- (void)setSimulatorProxy:(MOSSimulator*)sp {
  simProxy = sp;
  [self simulatorStateHasChanged];
}


- (MOSSimulator*)simulatorProxy {
  return simProxy;
}


- (void)awakeFromNib {
  CGFloat rowHeight;
  
  rowHeight = round([[self defaultMonospacedFont] boundingRectForFont].size.height);
  [tableView setRowHeight:rowHeight];
}


- (void)setDefaultMonospacedFont:(NSFont *)f {
  CGFloat rowHeight;
  
  [super setDefaultMonospacedFont:f];
  
  rowHeight = round([f boundingRectForFont].size.height);
  [tableView setRowHeight:rowHeight];
  [tableView reloadData];
}


- (void)dataHasChanged {
  [tableView reloadData];
}


- (void)simulatorStateHasChanged {
  [self dataHasChanged];
}


- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
  return NO;
}


@end
