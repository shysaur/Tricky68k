//
//  MOSSimulatorSubviewDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 17/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorSubviewDelegate.h"
#import "MOSSimulatorViewDefaults.h"


@implementation MOSSimulatorSubviewDelegate


- (instancetype)init {
  NSUserDefaults *ud;
  NSNotificationCenter *nc;
  
  self = [super init];
  
  ud = [NSUserDefaults standardUserDefaults];
  nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(userDefaultsDidChangeNotification:)
    name:NSUserDefaultsDidChangeNotification object:ud];
  [self reloadDefaultMonospacedFont];
  
  return self;
}


- (void)dealloc {
  NSUserDefaults *ud;
  NSNotificationCenter *nc;
  
  ud = [NSUserDefaults standardUserDefaults];
  nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self name:NSUserDefaultsDidChangeNotification object:ud];
}


- (void)reloadDefaultMonospacedFont {
  NSUserDefaults *ud;
  NSData *archivedFont;
  
  ud = [NSUserDefaults standardUserDefaults];
  archivedFont = [ud dataForKey:@"DebuggerTextFont"];
  if (archivedFont && oldArchivedFont && [archivedFont isEqual:oldArchivedFont])
    return;
  
  oldArchivedFont = archivedFont;
  viewFont = MOSSimulatorViewTeletypeFont();
  [self defaultMonospacedFontHasChanged];
}


- (void)userDefaultsDidChangeNotification:(NSNotification*)not {
  [self reloadDefaultMonospacedFont];
}


- (NSFont*)defaultMonospacedFont {
  return viewFont;
}


- (void)defaultMonospacedFontHasChanged {}


@end
