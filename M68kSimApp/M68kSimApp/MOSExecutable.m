//
//  MOSExecutable.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import "MOSExecutable.h"
#import "MOSSimulatorViewController.h"
#import "MOSSimulatorProxy.h"


@implementation MOSExecutable


+ (NSArray *)writableTypes {
  return @[];
}


- (NSString *)windowNibName {
  return @"MOSExecutable";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  [simVc setSimulatorProxy:simProxy];
  /* simProxy is the responsibility of the view controller from now on (the
   * restart button may change it) */
  simProxy = nil;
  [[aController window] setContentView:[simVc view]];
  [super windowControllerDidLoadNib:aController];
}


- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
  simProxy = [[MOSSimulatorProxy alloc] initWithExecutableURL:url];
  if ([simProxy simulatorState] == MOSSimulatorStateDead) {
    if (outError)
      *outError = [NSError errorWithDomain:MOSSimulatorViewErrorDomain
        code:MOSSimulatorViewErrorLoadingFailed
        userInfo:@{
          NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"This is "
            "often caused by trying to load an executable not built for the "
            "Motorola 68000 CPU.", @"Loading error recovery suggestion for "
            "the standalone simulator only")
        }];
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
