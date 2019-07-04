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


static void *AppearanceChangedContext = &AppearanceChangedContext;


@implementation MOSEditorPrefViewController


- (instancetype)init
{
  self = [super initWithNibName:@"MOSEditorPrefView" bundle:[NSBundle mainBundle]];
  [self view];
  editorFont = [[NSUserDefaults standardUserDefaults] unarchivedObjectForKey:MGSFragariaPrefsTextFont];
  [NSApp addObserver:self forKeyPath:@"effectiveAppearance" options:NSKeyValueObservingOptionInitial context:AppearanceChangedContext];
  [self resetColorSchemeBindings];
  return self;
}


- (void)dealloc
{
  [NSApp removeObserver:self forKeyPath:@"effectiveAppearance"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
  if (context == AppearanceChangedContext) {
    [self resetColorSchemeBindings];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}


- (void)resetColorSchemeBindings
{
  NSString *defaultsKey = MGSFragariaPrefsLightColourScheme;
  if (@available(macOS 10.14, *)) {
    NSAppearanceName look = [[NSApp effectiveAppearance] bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
    if ([look isEqual:NSAppearanceNameDarkAqua]) {
      defaultsKey = MGSFragariaPrefsDarkColourScheme;
    }
  }
  
  NSString *defaultsBinding = [NSString stringWithFormat:@"values.%@", defaultsKey];
  [self.colourSchemeTableViewDs bind:@"currentScheme" toObject:self.userDefaultsController withKeyPath:defaultsBinding options:@{NSValueTransformerNameBindingOption: MGSMutableColourSchemeFromPlistTransformerName}];
  [self.colorSchemeController bind:NSContentObjectBinding toObject:self.userDefaultsController withKeyPath:defaultsBinding options:@{NSValueTransformerNameBindingOption: MGSMutableColourSchemeFromPlistTransformerName}];
}


- (IBAction)setFontAction:(id)sender
{
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  [fontManager setSelectedFont:editorFont isMultiple:NO];
  [self.view.window makeFirstResponder:self.view];
  [fontManager orderFrontFontPanel:nil];
}


- (void)changeFont:(id)sender
{
  NSFontManager *fontManager = sender;
  NSFont *panelFont = [fontManager convertFont:editorFont];
  [[NSUserDefaults standardUserDefaults] setObjectByArchiving:panelFont forKey:MGSFragariaPrefsTextFont];
}


@end
