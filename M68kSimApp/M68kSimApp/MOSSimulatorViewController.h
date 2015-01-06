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


@interface MOSSimulatorViewController : NSViewController {
  MOSSimulatorProxy *simProxy;
  NSURL *simExec;
  BOOL simRunning;
  IBOutlet MOSSimDumpDataSource *dumpDs;
  IBOutlet MOSSimDisasmDataSource *disasmDs;
  IBOutlet MOSSimRegistersDataSource *regdumpDs;
  IBOutlet MOSSimStackDumpDataSource *stackDs;
}

- (void)setSimulatedExecutable:(NSURL*)url;
- (MOSSimulatorProxy*)simulatorProxy;

- (IBAction)run:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)stepIn:(id)sender;
- (IBAction)stepOver:(id)sender;

- (BOOL)isSimulatorRunning;
- (NSString *)flagsStatus;

@end
