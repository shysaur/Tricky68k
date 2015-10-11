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
  __weak MOSSimulator *weaksp = simProxy;
  __weak NSTableView *weaktv = tableView;
  dispatch_time_t somet;
  
  if (![simProxy isSimulatorRunning])
    [tableView reloadData];
  else {
    somet = dispatch_time(DISPATCH_TIME_NOW, 50000000);
    dispatch_after(somet, dispatch_get_main_queue(), ^{
      if ([weaksp isSimulatorRunning])
        [weaktv reloadData];
    });
  }
}


- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
  return NO;
}


@end
