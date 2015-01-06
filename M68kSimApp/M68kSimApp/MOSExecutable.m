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
  return @"MOSExecutable";
}


- (void)windowControllerWillLoadNib:(NSWindowController *)windowController {
  NSAssert(simVc, @"Simulator must exist at nib load");
  [simVc loadView];
  [simVc viewDidLoad];
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  [[aController window] setContentView:[simVc view]];
  [super windowControllerDidLoadNib:aController];
}


- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
  simVc = [[MOSSimulatorViewController alloc] initWithNibName:@"MOSSimulatorView"
                                                       bundle:[NSBundle mainBundle]];
  [simVc setSimulatedExecutable:url];
  return YES;
}


- (BOOL)isEntireFileLoaded {
  return YES;
}


@end
