//
//  MOSExecutable.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import "MOSExecutable.h"
#import "MOSSimulatorViewController.h"


@implementation MOSExecutable


+ (NSArray *)writableTypes {
  return @[];
}


- (NSString *)windowNibName {
  // Override returning the nib file name of the document
  // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
  return @"MOSExecutable";
}


- (void)windowControllerWillLoadNib:(NSWindowController *)windowController {
  NSAssert(simVc, @"Simulator must exist at nib load");
  [simVc loadView];
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  [[aController window] setContentView:[simVc view]];
  [super windowControllerDidLoadNib:aController];
  // Add any code here that needs to be executed once the windowController has loaded the document's window.
}


- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
  // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
  // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
  // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
  simVc = [[MOSSimulatorViewController alloc] initWithNibName:@"MOSSimulatorView" bundle:[NSBundle mainBundle]];
  [simVc setSimulatedExecutable:url];
  return YES;
}


- (BOOL)isEntireFileLoaded {
  return YES;
}


@end
