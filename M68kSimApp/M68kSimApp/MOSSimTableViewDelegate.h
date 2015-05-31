//
//  MOSSimTableViewDelegate.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 05/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>
#import "MOSSimulatorSubviewDelegate.h"


@class MOSSimulatorProxy;


@interface MOSSimTableViewDelegate : MOSSimulatorSubviewDelegate {
  IBOutlet NSTableView *tableView;
  MOSSimulatorProxy *simProxy;
}

- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp;
- (MOSSimulatorProxy*)simulatorProxy;

@end
