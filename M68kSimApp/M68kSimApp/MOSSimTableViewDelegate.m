//
//  MOSSimTableViewDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 05/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOS68kSimulator.h"
#import "MOSSimTableViewDelegate.h"


static void *ReloadTableView = &ReloadTableView;


@implementation MOSSimTableViewDelegate


- (instancetype)init {
  __weak MOSSimTableViewDelegate *weakself;
  
  weakself = self = [super init];
  
  voidTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
  dispatch_source_set_timer(voidTimer, DISPATCH_TIME_FOREVER, DISPATCH_TIME_FOREVER, 0);
  dispatch_source_set_event_handler(voidTimer, ^{
    MOSSimTableViewDelegate *strongself = weakself;
    [strongself->tableView reloadData];
  });
  dispatch_resume(voidTimer);
  
  return self;
}


- (void)dealloc {
  voidTimer = nil;
}


- (void)setSimulatorProxy:(MOS68kSimulator*)sp {
  simProxy = sp;
  [self simulatorStateHasChanged];
}


- (MOS68kSimulator*)simulatorProxy {
  return simProxy;
}


- (void)awakeFromNib {
  CGFloat rowHeight;
  
  rowHeight = round([[self defaultMonospacedFont] boundingRectForFont].size.height);
  [tableView setRowHeight:rowHeight];
}


- (void)defaultMonospacedFontHasChanged {
  CGFloat rowHeight;
  
  rowHeight = round([[self defaultMonospacedFont] boundingRectForFont].size.height);
  [tableView setRowHeight:rowHeight];
  [tableView reloadData];
}


- (void)dataHasChanged {
  [tableView reloadData];
}


- (void)simulatorStateHasChanged {
  dispatch_time_t somet;
  
  if (![simProxy isSimulatorRunning]) {
    dispatch_source_set_timer(voidTimer, DISPATCH_TIME_FOREVER, 0, 0);
    [self dataHasChanged];
  } else {
    somet = dispatch_time(DISPATCH_TIME_NOW, 50000000);
    dispatch_source_set_timer(voidTimer, somet, DISPATCH_TIME_FOREVER, 5000000);
  }
}


- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
  return NO;
}


@end
