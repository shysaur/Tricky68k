//
//  MOSSimulatorPrefViewController.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 17/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorPrefViewController.h"
#import "MOSSimulatorViewDefaults.h"


@implementation MOSSimulatorPrefViewController


- init {
  return [super initWithNibName:@"MOSSimulatorPrefView" bundle:[NSBundle mainBundle]];
}


- (void)loadView {
  [super loadView];
  [self updateFontPreview];
}


- (void)updateFontPreview {
  NSFont *viewFont;
  NSString *fontName;
  
  viewFont = MOSSimulatorViewTeletypeFont();
  fontName = [NSString stringWithFormat:@"%@ – %f", [viewFont displayName], [viewFont pointSize]];
  [fontPreviewView setStringValue:fontName];
  [fontPreviewView setFont:viewFont];
}


- (void)changeFont:(id)sender {
  NSFontManager *fm;
  NSFont *font;
  
  fm = [NSFontManager sharedFontManager];
  font = [fm convertFont:[fm selectedFont]];
  MOSSimulatorViewSetTeletypeFont(font);
  [self updateFontPreview];
}


- (IBAction)changeDebuggerFont:(id)sender {
  NSUserDefaults *ud;
  NSFontManager *fm;
  NSData *archivedFont;
  NSFont *viewFont;
  
  fm = [NSFontManager sharedFontManager];
  viewFont = MOSSimulatorViewTeletypeFont();
  [fm setSelectedFont:viewFont isMultiple:NO];
  [fm orderFrontFontPanel:self];
}


@end
