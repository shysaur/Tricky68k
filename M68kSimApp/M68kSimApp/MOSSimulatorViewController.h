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
@class MOSListingDictionary;
@class MOSExecutable;


@protocol MOSSimulatorViewParentWindowDelegate <NSWindowDelegate>

- (void)simulatorModeShouldTerminate:(id)sender;

- (void)breakpointsShouldSyncFromSimulator:(id)sender;
- (void)breakpointsShouldSyncToSimulator:(id)sender;

@end


@interface MOSSimulatorViewController : NSViewController {
  MOSSimulator *simProxy;
  MOSExecutable *simExec;
  NSTextStorage *source;
  MOSListingDictionary *listing;
  
  NSString *clockFreq;
  BOOL simRunning;
  BOOL viewHasLoaded;
  BOOL exceptionOccurred;
  BOOL stepping;
  dispatch_source_t clockUpdateTimer;
  BOOL showingSource;
  
  IBOutlet MOSSimDumpDataSource *dumpDs;
  IBOutlet MOSSimDisasmDataSource *disasmDs;
  IBOutlet MOSSimRegistersDataSource *regdumpDs;
  IBOutlet MOSSimStackDumpDataSource *stackDs;
  IBOutlet MOSTeletypeViewDelegate *ttyDelegate;
  IBOutlet NSView *ttyView;
  IBOutlet NSSplitView *mainSplitView;
  IBOutlet NSView *teletypePanel;
  __weak IBOutlet NSWindow *fallbackWindow;
  IBOutlet NSPopUpButton *sourcePopup;
  
  NSLayoutConstraint *teletypePanelConstraint;
  MOSSimBrkptWindowController *brkptWc;
}

- (BOOL)setSimulatedExecutable:(MOSExecutable *)exc simulatorType:(Class)st
    error:(NSError**)outerr;
- (BOOL)setSimulatedExecutable:(MOSExecutable *)exc simulatorType:(Class)st
    withSourceCode:(NSTextStorage*)src
    assembledToListing:(MOSListingDictionary*)ld error:(NSError**)outerr;
- (MOSExecutable *)simulatedExecutable;
- (void)setSimulatorProxy:(MOSSimulator*)sp;
- (MOSSimulator*)simulatorProxy;

- (BOOL)validateUserInterfaceItem:(id)anItem;

- (IBAction)run:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)restart:(id)sender;
- (IBAction)stepIn:(id)sender;
- (IBAction)stepOver:(id)sender;
- (IBAction)stepOut:(id)sender;

- (IBAction)openBreakpointsWindow:(id)sender;
- (void)replaceBreakpoints:(NSSet *)newbps;

- (IBAction)showSource:(id)sender;
- (IBAction)showDisassembly:(id)sender;

- (BOOL)isSimulatorRunning;
- (NSString *)flagsStatus;
- (NSString *)clockFrequency;

@end
