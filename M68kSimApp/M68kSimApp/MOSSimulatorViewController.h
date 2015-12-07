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


@class MOS68kSimulator;
@class MOSSimDumpDataSource;
@class MOSSimDisasmDataSource;
@class MOSSimRegistersDataSource;
@class MOSSimStackDumpDataSource;
@class MOSTeletypeViewDelegate;
@class MOSSimBrkptWindowController;


@protocol MOSSimulatorViewParentWindowDelegate <NSWindowDelegate>

- (void)simulatorModeShouldTerminate:(id)sender;

@end


@interface MOSSimulatorViewController : NSViewController {
  MOS68kSimulator *simProxy;
  NSURL *simExec;
  NSString *clockFreq;
  BOOL simRunning;
  BOOL viewHasLoaded;
  BOOL exceptionOccurred;
  BOOL stepping;
  dispatch_source_t clockUpdateTimer;
  IBOutlet MOSSimDumpDataSource *dumpDs;
  IBOutlet MOSSimDisasmDataSource *disasmDs;
  IBOutlet MOSSimRegistersDataSource *regdumpDs;
  IBOutlet MOSSimStackDumpDataSource *stackDs;
  IBOutlet MOSTeletypeViewDelegate *ttyDelegate;
  MOSSimBrkptWindowController *brkptWc;
}

- (BOOL)setSimulatedExecutable:(NSURL*)url error:(NSError**)outerr;
- (NSURL*)simulatedExecutable;
- (void)setSimulatorProxy:(MOS68kSimulator*)sp;
- (MOS68kSimulator*)simulatorProxy;

- (BOOL)validateUserInterfaceItem:(id)anItem;

- (IBAction)run:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)restart:(id)sender;
- (IBAction)stepIn:(id)sender;
- (IBAction)stepOver:(id)sender;
- (IBAction)openBreakpointsWindow:(id)sender;

- (BOOL)isSimulatorRunning;
- (NSString *)flagsStatus;
- (NSString *)clockFrequency;

@end
