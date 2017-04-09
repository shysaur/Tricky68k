//
//  MOSAssemblerPrefViewController.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 23/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSAssemblerPrefViewController.h"
#import "MOSPlatformManager.h"
#import "PlatformSupport.h"


@implementation MOSAssemblerPrefViewController {
  NSMutableArray<NSViewController *> *childVcs;
}


- init {
  self = [super initWithNibName:@"MOSAssemblerPrefView" bundle:[NSBundle mainBundle]];
  childVcs = [[NSMutableArray alloc] init];
  return self;
}


- (void)loadView {
  [super loadView];
  
  MOSPlatform *p = [[MOSPlatformManager sharedManager] defaultPlatform];
  NSViewController *vc = [p assemblerPreferencesViewController];
  if (vc) {
    [childVcs addObject:vc];
    [[self outerStackView] addView:[vc view] inGravity:NSStackViewGravityCenter];
  }
  
  if ([childVcs count] == 0) {
    [[self outerStackView] addView:[self placeholderView] inGravity:NSStackViewGravityCenter];
  }
}


@end





