//
//  MOSPrintAccessoryViewController.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 12/03/16.
//  Copyright © 2016 Daniele Cattaneo. All rights reserved.
//

#import "MOSPrintAccessoryViewController.h"
#import "MOSPrintingTextView.h"
#import "MOSDescribeFontTransformer.h"
#import "NSUserDefaults+Archiver.h"


NSString * const MOSDefaultsPrintFont = @"PrintFont";
NSString * const MOSDefaultsPrintColorScheme = @"PrintColorScheme";


@implementation MOSPrintAccessoryViewController


- (instancetype)init
{
  NSBundle *b;
  
  b = [NSBundle bundleForClass:[self class]];
  self = [self initWithNibName:@"MOSPrintAccessoryView" bundle:b];
  
  _textFont = [NSFont userFixedPitchFontOfSize:11.0];
  _colorScheme = [[MGSColourScheme alloc] init];
  
  return self;
}


- (void)setView:(NSView *)view
{
  NSPrintInfo *pi;
  id prevResp;
  
  [super setView:view];
  
  NSURL *schemeUrl = [[NSBundle mainBundle] URLForResource:@"Printing" withExtension:@"plist" subdirectory:@"Colour Schemes"];
  MGSColourScheme *scheme = [[MGSColourScheme alloc] initWithSchemeFileURL:schemeUrl error:nil];
  self.colourSchemeListController.disableCustomSchemes = YES;
  self.colourSchemeListController.defaultScheme = scheme;
  
  pi = self.representedObject;
  self.textFont = [pi.dictionary objectForKey:MOSPrintFont];
  self.colorScheme = [pi.dictionary objectForKey:MOSPrintColorScheme];
  
  if ([view nextResponder] != self) {
    prevResp = [view nextResponder];
    [view setNextResponder:self];
    [self setNextResponder:prevResp];
  }
}


- (void)setTextFont:(NSFont *)textFont
{
  _textFont = textFont;
  
  NSPrintInfo *pi = self.representedObject;
  [pi.dictionary setObject:_textFont forKey:MOSPrintFont];
  
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [ud setObjectByArchiving:textFont forKey:MOSDefaultsPrintFont];
}


- (void)setColorScheme:(MGSColourScheme *)colorScheme
{
  _colorScheme = colorScheme;
  
  NSPrintInfo *pi = self.representedObject;
  [pi.dictionary setObject:_colorScheme forKey:MOSPrintColorScheme];
  
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [ud setObject:[colorScheme propertyListRepresentation] forKey:MOSDefaultsPrintColorScheme];
}


- (void)changeFont:(id)sender
{
  NSFontManager *fm;
  
  fm = [NSFontManager sharedFontManager];
  self.textFont = [fm convertFont:baseFont];
}


- (IBAction)changeTextFont:(id)sender
{
  NSFontManager *fm;
  
  fm = [NSFontManager sharedFontManager];
  baseFont = self.textFont;
  [fm setSelectedFont:baseFont isMultiple:NO];
  [self.view.window makeFirstResponder:self];
  [fm orderFrontFontPanel:self];
}


- (NSArray *)localizedSummaryItems
{
  MOSDescribeFontTransformer *dft;
  NSString *fontDesc;
  
  dft = [[MOSDescribeFontTransformer alloc] init];
  fontDesc = [dft transformedValue:self.textFont];
  return @[
    @{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedString(@"Text Font",
        @"Print panel summary title for the font used for printing."),
      NSPrintPanelAccessorySummaryItemDescriptionKey: fontDesc}];
}


- (NSSet *)keyPathsForValuesAffectingPreview
{
  return [NSSet setWithObjects:@"textFont", @"colorScheme", nil];
}


@end
