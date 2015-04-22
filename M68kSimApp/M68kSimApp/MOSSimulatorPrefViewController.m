//
//  MOSSimulatorPrefViewController.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 17/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorPrefViewController.h"
#import "NSUserDefaults+Archiver.h"


@implementation MOSSimulatorPrefViewController


- init {
  return [super initWithNibName:@"MOSSimulatorPrefView" bundle:[NSBundle mainBundle]];
}


- (void)changeFont:(id)sender {
  NSFontManager *fm;
  NSFont *font;
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  fm = [NSFontManager sharedFontManager];
  font = [fm convertFont:baseFont];
  [ud setObjectByArchiving:font forKey:@"DebuggerTextFont"];
}


- (IBAction)changeDebuggerFont:(id)sender {
  NSFontManager *fm;
  NSUserDefaults *ud;
  
  ud = [NSUserDefaults standardUserDefaults];
  fm = [NSFontManager sharedFontManager];
  baseFont = [ud unarchivedObjectForKey:@"DebuggerTextFont" class:[NSFont class]];
  [fm setSelectedFont:baseFont isMultiple:NO];
  [fm orderFrontFontPanel:self];
}


@end
