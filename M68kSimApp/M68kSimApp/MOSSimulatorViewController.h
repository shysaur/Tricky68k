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
@class MOSSimStackDumpDataSource;
@class MOSTeletypeViewDelegate;


@interface MOSSimulatorViewController : NSViewController {
  MOSSimulatorProxy *simProxy;
  NSURL *simExec;
  BOOL simRunning;
  BOOL viewHasLoaded;
  IBOutlet MOSSimDumpDataSource *dumpDs;
  IBOutlet MOSSimDisasmDataSource *disasmDs;
  IBOutlet MOSSimRegistersDataSource *regdumpDs;
  IBOutlet MOSSimStackDumpDataSource *stackDs;
  IBOutlet MOSTeletypeViewDelegate *ttyDelegate;
}

- (BOOL)setSimulatedExecutable:(NSURL*)url error:(NSError**)outerr;
- (NSURL*)simulatedExecutable;
- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp;
- (MOSSimulatorProxy*)simulatorProxy;

- (BOOL)validateUserInterfaceItem:(id)anItem;

- (IBAction)run:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)restart:(id)sender;
- (IBAction)stepIn:(id)sender;
- (IBAction)stepOver:(id)sender;

- (BOOL)isSimulatorRunning;
- (NSString *)flagsStatus;

@end
