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


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  [[aController window] setContentView:[simVc view]];
  [super windowControllerDidLoadNib:aController];
}


- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
  simVc = [[MOSSimulatorViewController alloc] init];
  return [simVc setSimulatedExecutable:url error:outError];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
  if ([anItem action] == @selector(runPageLayout:)) return NO;
  if ([anItem action] == @selector(printDocument:)) return NO;
  return YES;
}


- (BOOL)isEntireFileLoaded {
  return YES;
}


- (BOOL)hasUnautosavedChanges {
  return NO;
}


@end
