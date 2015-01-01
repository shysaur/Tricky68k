//
//  MOSSimulatorViewController.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorProxy;
@class MOSSimDumpDataSource;
@class MOSSimDisasmDataSource;
@class MOSSimRegistersDataSource;


@interface MOSSimulatorViewController : NSViewController {
  MOSSimulatorProxy *simProxy;
  NSURL *simExec;
  BOOL simRunning;
  IBOutlet MOSSimDumpDataSource *dumpDs;
  IBOutlet NSTableView *dumpTv;
  IBOutlet MOSSimDisasmDataSource *disasmDs;
  IBOutlet NSTableView *disasmTv;
  IBOutlet MOSSimRegistersDataSource *regdumpDs;
  IBOutlet NSTableView *regdumpTv;
}

- (void)setSimulatedExecutable:(NSURL*)url;
- (MOSSimulatorProxy*)simulatorProxy;

- (IBAction)run:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)stepIn:(id)sender;
- (IBAction)stepOver:(id)sender;

- (BOOL)isSimulatorRunning;

@end
