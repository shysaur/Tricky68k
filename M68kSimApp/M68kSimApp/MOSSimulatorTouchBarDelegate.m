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
  SEL action;
  id target;
  
  NSCustomTouchBarItem *i = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
  NSButton *b = [[NSButton alloc] init];
  [b setBezelStyle:NSBezelStyleRounded];
  
  if ([identifier isEqual:MOSTouchBarItemIdentifierBuildAndRun]) {
    target = self.sourceDocument;
    imgname = @"MOSBuildAndRun";
    action = @selector(assembleAndRun:);
  } else {
    target = self.simulatorViewController;
    if ([identifier isEqual:MOSTouchBarItemIdentifierReset]) {
      imgname = @"MOSRestart";
      action = @selector(restart:);
    } else if ([identifier isEqual:MOSTouchBarItemIdentifierPlay]) {
      imgname = @"MOSStart";
      action = @selector(run:);
    } else if ([identifier isEqual:MOSTouchBarItemIdentifierPause]) {
      imgname = @"MOSPause";
      action = @selector(pause:);
    } else if ([identifier isEqual:MOSTouchBarItemIdentifierStepIn]) {
      imgname = @"MOSStepIn";
      action = @selector(stepIn:);
    } else if ([identifier isEqual:MOSTouchBarItemIdentifierStepOver]) {
      imgname = @"MOSStepOver";
      action = @selector(stepOver:);
    } else if ([identifier isEqual:MOSTouchBarItemIdentifierStepOut]) {
      imgname = @"MOSStepOut";
      action = @selector(stepOut:);
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
  return i;
}


@end
