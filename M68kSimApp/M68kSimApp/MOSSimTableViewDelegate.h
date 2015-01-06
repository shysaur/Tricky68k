//
//  MOSSimTableViewDelegate.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 05/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorProxy;


@interface MOSSimTableViewDelegate : NSObject {
  IBOutlet NSTableView *tableView;
  MOSSimulatorProxy *simProxy;
}

- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp;
- (MOSSimulatorProxy*)simulatorProxy;

@end
