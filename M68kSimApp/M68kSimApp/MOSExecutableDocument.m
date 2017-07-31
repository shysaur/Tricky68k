//
//  MOSExecutableDocument.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import "MOSExecutableDocument.h"
#import "MOSSimulatorViewController.h"
#import "MOSSimulator.h"
#import "MOSPlatform.h"
#import "MOSPlatformManager.h"
#import "MOSSimulatorTouchBarDelegate.h"


@interface MOSExecutableDocument ()

@property (nonatomic) MOSSimulatorTouchBarDelegate *touchBarDelegate;

@end


@implementation MOSExecutableDocument


+ (NSArray *)writableTypes {
  return @[];
}


- (NSString *)windowNibName {
  return @"MOSExecutableDocument";
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


- (NSTouchBar *)makeTouchBar {
  if (self.touchBarDelegate == nil) {
    [self setTouchBarDelegate:[[MOSSimulatorTouchBarDelegate alloc] init]];
    [self.touchBarDelegate setSimulatorViewController:simVc];
  }
  return [self.touchBarDelegate makeExecutableDocumentTouchBar];
}


- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
  NSError *tmpe;
  
  platform = [[MOSPlatformManager sharedManager] defaultPlatform];
  simProxy = [[[platform simulatorClass] alloc]
              initWithExecutableURL:url error:&tmpe];
  if (tmpe) {
    if (outError) *outError = tmpe;
    return NO;
  }
  return YES;
}


- (MOSPlatform *)currentPlatform {
  return platform;
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
