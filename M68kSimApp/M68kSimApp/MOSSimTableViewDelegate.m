//
//  MOSSimTableViewDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 05/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorProxy.h"
#import "MOSSimTableViewDelegate.h"


static void *ReloadTableView = &ReloadTableView;


@implementation MOSSimTableViewDelegate


- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp {
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorRunning" context:ReloadTableView];
  } @catch (NSException * __unused exception) {}
  simProxy = sp;
  [simProxy addObserver:self forKeyPath:@"simulatorRunning"
                options:NSKeyValueObservingOptionInitial context:ReloadTableView];
}


- (MOSSimulatorProxy*)simulatorProxy {
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


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object
  change:(NSDictionary*)change context:(void*)context {
  __weak MOSSimulatorProxy *weaksp = simProxy;
  __weak NSTableView *weaktv = tableView;
  dispatch_time_t somet;
  
  if (context == ReloadTableView) {
    if (![simProxy isSimulatorRunning])
      [tableView reloadData];
    else {
      somet = dispatch_time(DISPATCH_TIME_NOW, 50000000);
      dispatch_after(somet, dispatch_get_main_queue(), ^{
        if ([weaksp isSimulatorRunning])
          [weaktv reloadData];
      });
    }
  } else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (void)dealloc {
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorRunning" context:ReloadTableView];
  } @finally {}
}


@end
