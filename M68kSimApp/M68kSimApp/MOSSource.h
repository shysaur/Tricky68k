//
//  Document.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#include "MOSDocument.h"


@class MGSFragariaView;
@class SMLTextView;
@class MOSAssembler;
@class MOSSimulatorViewController;
@class MOSFragariaPreferencesObserver;
@class MOSJob;


@interface MOSSource : MOSDocument {
  /* AppKit already has a private window outlet, but it's not exposed
   * because NSDocument also supports multiple windows for the same document.
   * But, since we don't support that, it's just an annoyance. */
  __weak IBOutlet NSWindow *docWindow;
  BOOL simulatorMode;
  
  NSTextStorage *text;
  SMLTextView *textView;
  IBOutlet MGSFragariaView *fragaria;
  MOSFragariaPreferencesObserver *prefobs;
  
  IBOutlet MOSSimulatorViewController *simVc;
  NSView *simView;
  
  MOSAssembler *assembler;
  BOOL runWhenAssemblyComplete;
  MOSJob *lastJob;
  BOOL hadJob;
  NSURL *assemblyOutput;
  NSURL *tempSourceCopy;
}

- (IBAction)assemble:(id)sender;
- (IBAction)assembleAndRun:(id)sender;
- (IBAction)switchToSimulator:(id)sender;
- (IBAction)switchToEditor:(id)editor;

- (BOOL)simulatorModeSwitchAllowed;
- (BOOL)sourceModeSwitchAllowed;

@end

