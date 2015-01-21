//
//  Document.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@class MGSFragaria;
@class SMLTextView;
@class MOSAssembler;
@class MOSSimulatorViewController;


@interface MOSSource : NSDocument {
  NSData *initialData;
  
  /* AppKit already has a private window outlet, but it's not exposed
   * because NSDocument also supports multiple windows for the same document.
   * But, since we don't support that, it's just an annoyance. */
  IBOutlet NSWindow *docWindow;
  BOOL simulatorMode;
  
  SMLTextView *textView;
  MGSFragaria *fragaria;
  __strong IBOutlet NSView *editView;
  
  IBOutlet MOSSimulatorViewController *simVc;
  NSView *simView;
  
  MOSAssembler *assembler;
  BOOL runWhenAssemblyComplete;
  NSUInteger lastJobId;
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

