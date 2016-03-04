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
@class MOSSimBrkptWindowController;


@protocol MOSSimulatorViewParentWindowDelegate <NSWindowDelegate>

- (void)simulatorModeShouldTerminate:(id)sender;

@end


@interface MOSSimulatorViewController : NSViewController {
  MOSSimulator *simProxy;
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
  IBOutlet NSSplitView *mainSplitView;
  IBOutlet NSView *teletypePanel;
  NSLayoutConstraint *teletypePanelConstraint;
  MOSSimBrkptWindowController *brkptWc;
}

- (BOOL)setSimulatedExecutable:(NSURL*)url simulatorType:(Class)st
    error:(NSError**)outerr;
- (NSURL*)simulatedExecutable;
- (void)setSimulatorProxy:(MOSSimulator*)sp;
- (MOSSimulator*)simulatorProxy;

- (BOOL)validateUserInterfaceItem:(id)anItem;

- (IBAction)run:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)restart:(id)sender;
- (IBAction)stepIn:(id)sender;
- (IBAction)stepOver:(id)sender;

- (IBAction)openBreakpointsWindow:(id)sender;
- (void)replaceBreakpoints:(NSSet *)newbps;

- (BOOL)isSimulatorRunning;
- (NSString *)flagsStatus;
- (NSString *)clockFrequency;

@end
