//
//  MOSSimulatorViewDefaults.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 17/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorViewDefaults.h"


NSFont *MOSSimulatorViewTeletypeFont() {
  NSUserDefaults *ud;
  NSData *archivedFont;
  
  ud = [NSUserDefaults standardUserDefaults];
  archivedFont = [ud dataForKey:@"DebuggerTextFont"];
  if (!archivedFont)
    return [NSFont fontWithName:@"Menlo" size:11.0];
  return [NSUnarchiver unarchiveObjectWithData:archivedFont];
}


void MOSSimulatorViewSetTeletypeFont(NSFont *font) {
  NSUserDefaults *ud;
  NSData *archivedFont;
  
  ud = [NSUserDefaults standardUserDefaults];
  archivedFont = [NSArchiver archivedDataWithRootObject:font];
  [ud setObject:archivedFont forKey:@"DebuggerTextFont"];
}

