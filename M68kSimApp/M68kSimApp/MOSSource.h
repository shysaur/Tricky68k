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
@class MOSAssembler;
@class MOSSimulatorViewController;


@interface MOSSource : NSDocument {
  NSData *initialData;
  
  BOOL simulatorMode;
  
  NSTextView *textView;
  MGSFragaria *fragaria;
  __strong IBOutlet NSView *editView;
  
  MOSSimulatorViewController *simVc;
  NSView *simView;
  
  MOSAssembler *assembler;
  NSUInteger lastJobId;
  BOOL hadJob;
  NSURL *assemblyOutput;
  NSURL *tempSourceCopy;
}

- (IBAction)assembleAndRun:(id)sender;

@end

