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


@implementation MOSPrintAccessoryViewController


- (instancetype)init {
  NSBundle *b;
  
  b = [NSBundle bundleForClass:[self class]];
  self = [self initWithNibName:@"MOSPrintAccessoryView" bundle:b];
  _textFont = [NSFont userFixedPitchFontOfSize:11.0];
  return self;
}


- (void)setView:(NSView *)view {
  NSPrintInfo *pi;
  id prevResp;
  
  [super setView:view];
  pi = self.representedObject;
  self.textFont = [pi.dictionary objectForKey:MOSPrintFont];
  
  if ([view nextResponder] != self) {
    prevResp = [view nextResponder];
    [view setNextResponder:self];
    [self setNextResponder:prevResp];
  }
}


- (void)setTextFont:(NSFont *)textFont {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSPrintInfo *pi;
  
  _textFont = textFont;
  pi = self.representedObject;
  [pi.dictionary setObject:_textFont forKey:MOSPrintFont];
  [ud setObjectByArchiving:textFont forKey:MOSDefaultsPrintFont];
}


- (void)changeFont:(id)sender {
  NSFontManager *fm;
  
  fm = [NSFontManager sharedFontManager];
  self.textFont = [fm convertFont:baseFont];
}


- (IBAction)changeTextFont:(id)sender {
  NSFontManager *fm;
  
  fm = [NSFontManager sharedFontManager];
  baseFont = self.textFont;
  [fm setSelectedFont:baseFont isMultiple:NO];
  [self.view.window makeFirstResponder:self];
  [fm orderFrontFontPanel:self];
}


- (NSArray *)localizedSummaryItems {
  MOSDescribeFontTransformer *dft;
  NSString *fontDesc;
  
  dft = [[MOSDescribeFontTransformer alloc] init];
  fontDesc = [dft transformedValue:self.textFont];
  return @[
    @{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedString(@"Text Font",
        @"Print panel summary title for the font used for printing."),
      NSPrintPanelAccessorySummaryItemDescriptionKey: fontDesc}];
}


- (NSSet *)keyPathsForValuesAffectingPreview {
  return [NSSet setWithObject:@"textFont"];
}


@end
