//
//  MOSSimulatorTouchBarDelegate.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 06/04/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorTouchBarDelegate.h"
#import "MOSSimulatorViewController.h"
#import "MOSSource.h"


NSString * const MOSSourceDocumentTouchBarId = @"MOSSourceDocumentTouchBarId";
NSString * const MOSExecutableDocumentTouchBarId = @"MOSExecutableDocumentTouchBarId";

NSString * const MOSTouchBarItemIdentifierReset = @"MOSTouchBarItemIdentifierReset";
NSString * const MOSTouchBarItemIdentifierPlay = @"MOSTouchBarItemIdentifierPlay";
NSString * const MOSTouchBarItemIdentifierPause = @"MOSTouchBarItemIdentifierPause";
NSString * const MOSTouchBarItemIdentifierStepIn = @"MOSTouchBarItemIdentifierStepIn";
NSString * const MOSTouchBarItemIdentifierStepOver = @"MOSTouchBarItemIdentifierStepOver";
NSString * const MOSTouchBarItemIdentifierStepOut = @"MOSTouchBarItemIdentifierStepOut";
NSString * const MOSTouchBarItemIdentifierBuildAndRun = @"MOSTouchBarItemIdentifierBuildAndRun";



@implementation MOSSimulatorTouchBarDelegate


- (NSTouchBar *)makeSourceDocumentTouchBar
{
  NSTouchBar *tb = [[NSTouchBar alloc] init];
  [tb setDelegate:self];
  [tb setCustomizationIdentifier:MOSSourceDocumentTouchBarId];
  [tb setDefaultItemIdentifiers:@[
    MOSTouchBarItemIdentifierPlay,
    MOSTouchBarItemIdentifierPause,
    NSTouchBarItemIdentifierFixedSpaceSmall,
    MOSTouchBarItemIdentifierReset,
    NSTouchBarItemIdentifierFixedSpaceSmall,
    MOSTouchBarItemIdentifierBuildAndRun,
    NSTouchBarItemIdentifierFlexibleSpace,
    NSTouchBarItemIdentifierOtherItemsProxy,
    NSTouchBarItemIdentifierFlexibleSpace,
    MOSTouchBarItemIdentifierStepIn,
    MOSTouchBarItemIdentifierStepOver,
    MOSTouchBarItemIdentifierStepOut
  ]];
  return tb;
}


- (NSTouchBar *)makeExecutableDocumentTouchBar
{
  NSTouchBar *tb = [[NSTouchBar alloc] init];
  [tb setDelegate:self];
  [tb setCustomizationIdentifier:MOSSourceDocumentTouchBarId];
  [tb setDefaultItemIdentifiers:@[
    MOSTouchBarItemIdentifierPlay,
    MOSTouchBarItemIdentifierPause,
    NSTouchBarItemIdentifierFixedSpaceSmall,
    MOSTouchBarItemIdentifierReset,
    NSTouchBarItemIdentifierFlexibleSpace,
    NSTouchBarItemIdentifierOtherItemsProxy,
    NSTouchBarItemIdentifierFlexibleSpace,
    MOSTouchBarItemIdentifierStepIn,
    MOSTouchBarItemIdentifierStepOver,
    MOSTouchBarItemIdentifierStepOut
  ]];
  return tb;
}


- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
  NSString *imgname;
  NSString *label;
  SEL action;
  id target;
  
  NSCustomTouchBarItem *i = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
  NSButton *b = [[NSButton alloc] init];
  [b setBezelStyle:NSBezelStyleRounded];
  
  if ([identifier isEqual:MOSTouchBarItemIdentifierBuildAndRun]) {
    target = self.sourceDocument;
    imgname = @"MOSBuildAndRun";
    action = @selector(assembleAndRun:);
    label = NSLocalizedString(@"Assemble and Run", @"Toolbar Item");
  } else {
    target = self.simulatorViewController;
    if ([identifier isEqual:MOSTouchBarItemIdentifierReset]) {
      imgname = @"MOSRestart";
      action = @selector(restart:);
      label = NSLocalizedString(@"Restart", @"Toolbar Item");
    } else if ([identifier isEqual:MOSTouchBarItemIdentifierPlay]) {
      imgname = @"MOSStart";
      action = @selector(run:);
      label = NSLocalizedString(@"Start", @"Toolbar Item");
    } else if ([identifier isEqual:MOSTouchBarItemIdentifierPause]) {
      imgname = @"MOSPause";
      action = @selector(pause:);
      label = NSLocalizedString(@"Pause", @"Toolbar Item");
    } else if ([identifier isEqual:MOSTouchBarItemIdentifierStepIn]) {
      imgname = @"MOSStepIn";
      action = @selector(stepIn:);
      label = NSLocalizedString(@"Step In", @"Toolbar Item");
    } else if ([identifier isEqual:MOSTouchBarItemIdentifierStepOver]) {
      imgname = @"MOSStepOver";
      action = @selector(stepOver:);
      label = NSLocalizedString(@"Step Over", @"Toolbar Item");
    } else if ([identifier isEqual:MOSTouchBarItemIdentifierStepOut]) {
      imgname = @"MOSStepOut";
      action = @selector(stepOut:);
      label = NSLocalizedString(@"Step Out", @"Toolbar Item");
    } else {
      return nil;
    }
  }

  NSImage *img = [[NSImage imageNamed:imgname] copy];
  [img setTemplate:YES];
  [img setSize:NSMakeSize(20, 20)];
  [b setImage:img];
  [b setTarget:target];
  [b setAction:action];
  
  [i setView:b];
  [i setCustomizationLabel:label];
  return i;
}


@end
