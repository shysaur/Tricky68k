//
//  MOSSimulatorPrefViewController.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 17/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSSimulatorPrefViewController.h"
#import "NSUserDefaults+Archiver.h"
#import "MOSPlatformManager.h"
#import "PlatformSupport.h"


@implementation MOSSimulatorPrefViewController


- (instancetype)init {
  self = [super initWithNibName:@"MOSSimulatorPrefView" bundle:[NSBundle mainBundle]];
  childVcs = [[NSMutableArray alloc] init];
  return self;
}


- (void)loadView {
  [super loadView];
  
  MOSPlatform *p = [[MOSPlatformManager sharedManager] defaultPlatform];
  NSViewController *vc = [p simulatorPreferencesViewController];
  NSStackView *sv = [self pluginPrefsView];
  if (vc) {
    [childVcs addObject:vc];
    [sv addView:[self separatorView] inGravity:NSStackViewGravityCenter];
    [sv addView:[vc view] inGravity:NSStackViewGravityCenter];
  }
  [[self view] layoutSubtreeIfNeeded];
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
  [self.view.window makeFirstResponder:self.view];
  [fm orderFrontFontPanel:self];
}


@end
