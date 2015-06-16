//
//  MOSSimulatorViewController.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>


extern NSString * const MOSSimulatorViewErrorDomain;

enum {
  MOSSimulatorViewErrorNone,
  MOSSimulatorViewErrorLoadingFailed
};


@class MOSSimulator;
@class MOSSimDumpDataSource;
@class MOSSimDisasmDataSource;
@class MOSSimRegistersDataSource;
@class MOSSimStackDumpDataSource;
@class MOSTeletypeViewDelegate;


@protocol MOSSimulatorViewParentWindowDelegate <NSWindowDelegate>

- (void)simulatorModeShouldTerminate:(id)sender;

@end


@interface MOSSimulatorViewController : NSViewController {
  MOSSimulator *simProxy;
  NSURL *simExec;
  BOOL simRunning;
  BOOL viewHasLoaded;
  BOOL exceptionOccurred;
  IBOutlet MOSSimDumpDataSource *dumpDs;
  IBOutlet MOSSimDisasmDataSource *disasmDs;
  IBOutlet MOSSimRegistersDataSource *regdumpDs;
  IBOutlet MOSSimStackDumpDataSource *stackDs;
  IBOutlet MOSTeletypeViewDelegate *ttyDelegate;
}

- (BOOL)setSimulatedExecutable:(NSURL*)url error:(NSError**)outerr;
- (NSURL*)simulatedExecutable;
- (void)setSimulatorProxy:(MOSSimulator*)sp;
- (MOSSimulator*)simulatorProxy;

- (BOOL)validateUserInterfaceItem:(id)anItem;

- (IBAction)run:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)restart:(id)sender;
- (IBAction)stepIn:(id)sender;
- (IBAction)stepOver:(id)sender;

- (BOOL)isSimulatorRunning;
- (NSString *)flagsStatus;

@end
