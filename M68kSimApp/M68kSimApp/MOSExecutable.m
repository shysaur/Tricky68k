//
//  MOSExecutable.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import "MOSExecutable.h"
#import "MOSSimulatorViewController.h"
#import "MOSSimulator.h"


@implementation MOSExecutable


+ (NSArray *)writableTypes {
  return @[];
}


- (NSString *)windowNibName {
  return @"MOSExecutable";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  NSView *simView;
  NSResponder *oldresp;
  
  [simVc setSimulatorProxy:simProxy];
  /* simProxy is the responsibility of the view controller from now on (the
   * restart button may change it) */
  simProxy = nil;
  simView = [simVc view];
  [[aController window] setContentView:simView];
  
  /* Install the view controller in the responder chain */
  oldresp = [simView nextResponder];
  if (oldresp != simVc) {
    /* Since Yosemite, AppKit will try to do this automatically */
    [simView setNextResponder:simVc];
    [simVc setNextResponder:oldresp];
  }
  
  [super windowControllerDidLoadNib:aController];
}


- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
  NSError *tmpe;
  
  simProxy = [[MOSSimulator alloc] initWithExecutableURL:url error:&tmpe];
  if (tmpe) {
    if (outError) *outError = tmpe;
    return NO;
  }
  return YES;
}


- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {
  if ([anItem action] == @selector(runPageLayout:)) return NO;
  if ([anItem action] == @selector(printDocument:)) return NO;
  return [super validateUserInterfaceItem:anItem];
}


- (BOOL)isEntireFileLoaded {
  return YES;
}


- (BOOL)hasUnautosavedChanges {
  return NO;
}


- (BOOL)isTransient {
  return NO;
}


@end
