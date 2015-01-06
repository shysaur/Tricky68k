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


- (void)observeValueForKeyPath:(NSString*)keyPath    ofObject:(id)object
                        change:(NSDictionary*)change context:(void*)context {
  if (context == ReloadTableView) {
    [tableView reloadData];
  } else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (void)dealloc {
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorRunning" context:ReloadTableView];
  } @finally {}
}


@end
