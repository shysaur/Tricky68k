//
//  MOSSimTableViewDelegate.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 05/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>
#import "MOSSimulatorSubviewDelegate.h"


@class MOS68kSimulator;


@interface MOSSimTableViewDelegate : MOSSimulatorSubviewDelegate {
  IBOutlet NSTableView *tableView;
  MOS68kSimulator *simProxy;
  dispatch_source_t voidTimer;
}

- (void)setSimulatorProxy:(MOS68kSimulator*)sp;
- (MOS68kSimulator*)simulatorProxy;

- (void)dataHasChanged;
- (void)simulatorStateHasChanged;

@end
