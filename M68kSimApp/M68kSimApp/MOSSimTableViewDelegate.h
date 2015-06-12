//
//  MOSSimTableViewDelegate.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 05/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>
#import "MOSSimulatorSubviewDelegate.h"


@class MOSSimulator;


@interface MOSSimTableViewDelegate : MOSSimulatorSubviewDelegate {
  IBOutlet NSTableView *tableView;
  MOSSimulator *simProxy;
}

- (void)setSimulatorProxy:(MOSSimulator*)sp;
- (MOSSimulator*)simulatorProxy;

@end
