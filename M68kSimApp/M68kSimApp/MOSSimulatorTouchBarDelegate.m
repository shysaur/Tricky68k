//
//  MOSSimulatorTouchBarDelegate.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 06/04/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorTouchBarDelegate.h"
#import "MOSSimulatorViewController.h"


NSString * const MOSSourceDocumentTouchBarId = @"MOSSourceDocumentTouchBarId";
NSString * const MOSExecutableDocumentTouchBarId = @"MOSExecutableDocumentTouchBarId";

NSString * const MOSTouchBarItemIdentifierReset = @"MOSTouchBarItemIdentifierReset";


@implementation MOSSimulatorTouchBarDelegate


- (NSTouchBar *)makeSourceDocumentTouchBar
{
  NSTouchBar *tb = [[NSTouchBar alloc] init];
  [tb setDelegate:self];
  [tb setCustomizationIdentifier:MOSSourceDocumentTouchBarId];
  [tb setDefaultItemIdentifiers:@[
    MOSTouchBarItemIdentifierReset,
    NSTouchBarItemIdentifierOtherItemsProxy
  ]];
  return tb;
}


- (NSTouchBar *)makeExecutableDocumentTouchBar
{
  NSTouchBar *tb = [[NSTouchBar alloc] init];
  [tb setDelegate:self];
  [tb setCustomizationIdentifier:MOSSourceDocumentTouchBarId];
  [tb setDefaultItemIdentifiers:@[
    MOSTouchBarItemIdentifierReset,
    NSTouchBarItemIdentifierOtherItemsProxy
  ]];
  return tb;
}


- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
  if ([identifier isEqual:MOSTouchBarItemIdentifierReset]) {
    NSCustomTouchBarItem *i = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
    NSButton *b = [[NSButton alloc] init];
    NSImage *img = [NSImage imageNamed:@"MOSRestart"];
    [img setTemplate:YES];
    [b setImage:img];
    [b setBezelStyle:NSBezelStyleRounded];
    [b setTarget:self.simulatorViewController];
    [b setAction:@selector(restart:)];
    [i setView:b];
    return i;
  }
  return nil;
}


@end
