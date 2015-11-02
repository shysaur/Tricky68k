//
//  MOSSimulatorToolbarDelegate.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/11/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorToolbarDelegate.h"
#import "MOSSimulatorViewController.h"
#import "MOSViewValidatingToolbarItem.h"
#import "MOSSource.h"


NSString * const MOSToolbarItemIdentifierPlay = @"MOSToolbarItemIdentifierPlay";
NSString * const MOSToolbarItemIdentifierPause = @"MOSToolbarItemIdentifierPause";
NSString * const MOSToolbarItemIdentifierStepIn = @"MOSToolbarItemIdentifierStepIn";
NSString * const MOSToolbarItemIdentifierStepOut = @"MOSToolbarItemIdentifierStepOut";
NSString * const MOSToolbarItemIdentifierFlags = @"MOSToolbarItemIdentifierFlags";
NSString * const MOSToolbarItemIdentifierRunning = @"MOSToolbarItemIdentifierRunning";
NSString * const MOSToolbarItemIdentifierClock = @"MOSToolbarItemIdentifierClock";
NSString * const MOSToolbarItemIdentifierReset = @"MOSToolbarItemIdentifierReset";
NSString * const MOSToolbarItemIdentifierBuildAndRun = @"MOSToolbarItemIdentifierBuildAndRun";
NSString * const MOSToolbarItemIdentifierGoSource = @"MOSToolbarItemIdentifierGoSource";
NSString * const MOSToolbarItemIdentifierGoSimulator= @"MOSToolbarItemIdentifierGoSimulator";


@implementation MOSSimulatorToolbarDelegate


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
  NSArray *commonSet;
  
  commonSet =  @[
    NSToolbarSpaceItemIdentifier,
    NSToolbarFlexibleSpaceItemIdentifier,
    MOSToolbarItemIdentifierPlay,
    MOSToolbarItemIdentifierPause,
    MOSToolbarItemIdentifierStepIn,
    MOSToolbarItemIdentifierStepOut,
    MOSToolbarItemIdentifierFlags,
    MOSToolbarItemIdentifierRunning,
    MOSToolbarItemIdentifierClock,
    MOSToolbarItemIdentifierReset ];
  if (!sourceDocument)
    return commonSet;
  return [commonSet arrayByAddingObjectsFromArray:@[
    MOSToolbarItemIdentifierBuildAndRun,
    MOSToolbarItemIdentifierGoSource,
    MOSToolbarItemIdentifierGoSimulator ]];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  if (!sourceDocument)
    return @[
      MOSToolbarItemIdentifierPlay,
      MOSToolbarItemIdentifierPause,
      MOSToolbarItemIdentifierStepIn,
      MOSToolbarItemIdentifierStepOut,
      MOSToolbarItemIdentifierFlags,
      NSToolbarFlexibleSpaceItemIdentifier,
      MOSToolbarItemIdentifierClock,
      MOSToolbarItemIdentifierRunning,
      MOSToolbarItemIdentifierReset ];
  return @[
    MOSToolbarItemIdentifierGoSource,
    MOSToolbarItemIdentifierBuildAndRun,
    MOSToolbarItemIdentifierPlay,
    MOSToolbarItemIdentifierPause,
    MOSToolbarItemIdentifierStepIn,
    MOSToolbarItemIdentifierStepOut,
    MOSToolbarItemIdentifierFlags,
    NSToolbarFlexibleSpaceItemIdentifier,
    MOSToolbarItemIdentifierClock,
    MOSToolbarItemIdentifierRunning,
    MOSToolbarItemIdentifierReset,
    MOSToolbarItemIdentifierGoSimulator ];
}


- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  return @[];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  NSToolbarItem *res;
  id view;
  NSString *label;
  NSImage *image;
  SEL action;
  NSArray *system = @[
    NSToolbarSpaceItemIdentifier,
    NSToolbarFlexibleSpaceItemIdentifier ];
  NSArray *buttons = @[
    MOSToolbarItemIdentifierPlay,
    MOSToolbarItemIdentifierPause,
    MOSToolbarItemIdentifierStepIn,
    MOSToolbarItemIdentifierStepOut,
    MOSToolbarItemIdentifierReset,
    MOSToolbarItemIdentifierGoSource,
    MOSToolbarItemIdentifierGoSimulator,
    MOSToolbarItemIdentifierBuildAndRun ];
  NSArray *sourceButtons = @[
    MOSToolbarItemIdentifierGoSource,
    MOSToolbarItemIdentifierGoSimulator,
    MOSToolbarItemIdentifierBuildAndRun ];
  NSArray *text = @[
    MOSToolbarItemIdentifierFlags,
    MOSToolbarItemIdentifierClock ];
  
  res = [[MOSViewValidatingToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
  if (![system containsObject:itemIdentifier]) {
    
    if ([buttons containsObject:itemIdentifier]) {
      view = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 100, 32)];
      [view setBezelStyle:NSTexturedRoundedBezelStyle];
      if ([sourceButtons containsObject:itemIdentifier]) {
        [view setTarget:sourceDocument];
        if ([itemIdentifier isEqual:MOSToolbarItemIdentifierGoSource]) {
          image = [NSImage imageNamed:NSImageNameLeftFacingTriangleTemplate];
          label = NSLocalizedString(@"Source", @"Toolbar Item");
          action = @selector(switchToEditor:);
          [view setImagePosition:NSImageLeft];
          [view setTitle:label];
        } else if ([itemIdentifier isEqual:MOSToolbarItemIdentifierGoSimulator]) {
          image = [NSImage imageNamed:NSImageNameRightFacingTriangleTemplate];
          label = NSLocalizedString(@"Simulator", @"Toolbar Item");
          action = @selector(switchToSimulator:);
          [view setImagePosition:NSImageRight];
          [view setTitle:label];
        } else if ([itemIdentifier isEqual:MOSToolbarItemIdentifierBuildAndRun]) {
          image = [NSImage imageNamed:@"MOSBuildAndRun"];
          label = NSLocalizedString(@"Assemble and Run", @"Toolbar Item");
          action = @selector(assembleAndRun:);
          [view setTitle:@""];
        }
        [view setAction:action];
        [view setImage:image];
        [view sizeToFit];
      } else {
        [view setTarget:simulatorVc];
        if ([itemIdentifier isEqual:MOSToolbarItemIdentifierPlay]) {
          image = [NSImage imageNamed:@"MOSStart"];
          label = NSLocalizedString(@"Start", @"Toolbar Item");
          action = @selector(run:);
        } else if ([itemIdentifier isEqual:MOSToolbarItemIdentifierPause]) {
          image = [NSImage imageNamed:@"MOSPause"];
          label = NSLocalizedString(@"Pause", @"Toolbar Item");
          action = @selector(pause:);
        } else if ([itemIdentifier isEqual:MOSToolbarItemIdentifierStepIn]) {
          image = [NSImage imageNamed:@"MOSStepIn"];
          label = NSLocalizedString(@"Step In", @"Toolbar Item");
          action = @selector(stepIn:);
        } else if ([itemIdentifier isEqual:MOSToolbarItemIdentifierStepOut]) {
          image = [NSImage imageNamed:@"MOSStepOver"];
          label = NSLocalizedString(@"Step Over", @"Toolbar Item");
          action = @selector(stepOver:);
        } else if ([itemIdentifier isEqual:MOSToolbarItemIdentifierReset]) {
          image = [NSImage imageNamed:@"MOSRestart"];
          label = NSLocalizedString(@"Restart", @"Toolbar Item");
          action = @selector(restart:);
        }
        [view setTitle:@""];
        [view setAction:action];
        [view setImage:image];
        [view sizeToFit];
      }
      
    } else if ([text containsObject:itemIdentifier]) {
      view = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 100, 32)];
      if ([itemIdentifier isEqual:MOSToolbarItemIdentifierFlags]) {
        label = NSLocalizedString(@"Flags", @"Toolbar Item");
        [view setObjectValue:@"X:0 N:0 Z:0 V:0 C:0"];
        [view setFont:[NSFont userFixedPitchFontOfSize:11]];
        [view sizeToFit];
        [view bind:@"objectValue" toObject:simulatorVc withKeyPath:@"flagsStatus" options:nil];
      } else if ([itemIdentifier isEqual:MOSToolbarItemIdentifierClock]) {
        label = NSLocalizedString(@"Clock Frequency", @"Toolbar Item");
        [view setObjectValue:@"123.4 MHz"];
        [view setFont:[NSFont systemFontOfSize:11]];
        [view setAlignment:NSTextAlignmentCenter];
        [view sizeToFit];
        [view bind:@"value" toObject:simulatorVc withKeyPath:@"clockFrequency" options:nil];
      }
      [view setBezeled:NO];
      [view setBordered:NO];
      [view setDrawsBackground:NO];
      [view setEditable:NO];
      
    } else if ([itemIdentifier isEqual:MOSToolbarItemIdentifierRunning]) {
      view = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 16, 16)];
      [view setIndeterminate:YES];
      [(NSProgressIndicator *)view setStyle:NSProgressIndicatorSpinningStyle];
      [view setControlSize:NSSmallControlSize];
      if (flag)
        [view bind:@"animate" toObject:simulatorVc withKeyPath:@"simulatorRunning" options:nil];
      label = NSLocalizedString(@"Running", @"Toolbar Item");
    }
    
    [res setView:view];
    [res setLabel:label];
    [res setPaletteLabel:label];
  }
  return res;
}


@end
