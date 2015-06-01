//
//  MOSEditorPrefViewController.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 15/03/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSEditorPrefViewController.h"
#import "NSUserDefaults+Archiver.h"
#import <Fragaria/Fragaria.h>
#import "MOSFragariaPreferencesObserver.h"


@implementation MOSEditorPrefViewController


- init {
  self = [super initWithNibName:@"MOSEditorPrefView" bundle:[NSBundle mainBundle]];
  editorFont = [[NSUserDefaults standardUserDefaults] unarchivedObjectForKey:MGSFragariaPrefsTextFont];
  return self;
}


- (IBAction)setFontAction:(id)sender
{
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  [fontManager setSelectedFont:editorFont isMultiple:NO];
  [fontManager orderFrontFontPanel:nil];
}


- (void)changeFont:(id)sender
{
  NSFontManager *fontManager = sender;
  NSFont *panelFont = [fontManager convertFont:editorFont];
  [[NSUserDefaults standardUserDefaults] setObjectByArchiving:panelFont forKey:MGSFragariaPrefsTextFont];
}


@end
