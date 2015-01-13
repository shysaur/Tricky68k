//
//  Document.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MGSFragaria;
@class MOSAssembler;


@interface MOSSource : NSDocument {
  NSTextView *textView;
  NSData *initialData;
  MGSFragaria *fragaria;
  MOSAssembler *assembler;
  NSUInteger lastJobId;
  BOOL hadJob;
  NSURL *assemblyOutput;
  NSURL *tempSourceCopy;
  IBOutlet NSView *editView;
}

- (IBAction)assembleAndRun:(id)sender;

@end

