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


- (void)loadView {
  [super loadView];
  ptSizeFormatter = [[NSNumberFormatter alloc] init];
  [ptSizeFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
  [self updateFontPreview];
}


- (void)updateFontPreview {
  NSFont *viewFont;
  NSString *fontName;
  NSString *sizeString;
  NSUserDefaults *ud;
  
  ud = [NSUserDefaults standardUserDefaults];
  viewFont = [ud unarchivedObjectForKey:@"DebuggerTextFont" class:[NSFont class]];
  sizeString = [ptSizeFormatter stringFromNumber:[NSNumber numberWithFloat:[viewFont pointSize]]];
  fontName = [NSString stringWithFormat:@"%@ – %@", [viewFont displayName], sizeString];
  
  [fontPreviewView setStringValue:fontName];
  [fontPreviewView setFont:viewFont];
}


- (void)changeFont:(id)sender {
  NSFontManager *fm;
  NSFont *font;
  
  fm = [NSFontManager sharedFontManager];
  font = [fm convertFont:baseFont];
  [[NSUserDefaults standardUserDefaults] setObjectByArchiving:font forKey:@"DebuggerTextFont"];
  [self updateFontPreview];
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
