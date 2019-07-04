//
//  MGSTemporaryPreferencesObserver.m
//  Fragaria
//
//  Created by Jim Derry on 2/27/15.
//
//

#import <Cocoa/Cocoa.h>
#import <Fragaria/Fragaria.h>
#import "MOSFragariaPreferencesObserver.h"


/* archived colour */
NSString * const MGSFragariaPrefsGutterTextColourWell = @"FragariaGutterTextColourWell";

/* bool */
NSString * const MGSFragariaPrefsShowLineNumberGutter = @"FragariaShowLineNumberGutter";
NSString * const MGSFragariaPrefsSyntaxColourNewDocuments = @"FragariaSyntaxColourNewDocuments";
NSString * const MGSFragariaPrefsLineWrapNewDocuments = @"FragariaLineWrapNewDocuments";
NSString * const MGSFragariaPrefsIndentNewLinesAutomatically = @"FragariaIndentNewLinesAutomatically";
NSString * const MGSFragariaPrefsOnlyColourTillTheEndOfLine = @"FragariaOnlyColourTillTheEndOfLine";
NSString * const MGSFragariaPrefsShowMatchingBraces = @"FragariaShowMatchingBraces";
NSString * const MGSFragariaPrefsShowInvisibleCharacters = @"FragariaShowInvisibleCharacters";
NSString * const MGSFragariaPrefsIndentWithSpaces = @"FragariaIndentWithSpaces";
NSString * const MGSFragariaPrefsColourMultiLineStrings = @"FragariaColourMultiLineStrings";
NSString * const MGSFragariaPrefsAutocompleteSuggestAutomatically = @"FragariaAutocompleteSuggestAutomatically";
NSString * const MGSFragariaPrefsAutocompleteIncludeStandardWords = @"FragariaAutocompleteIncludeStandardWords";
NSString * const MGSFragariaPrefsUseTabStops = @"FragariaUseTabStops";
NSString * const MGSFragariaPrefsHighlightCurrentLine = @"FragariaHighlightCurrentLine";
NSString * const MGSFragariaPrefsAutomaticallyIndentBraces = @"FragariaAutomaticallyIndentBraces";
NSString * const MGSFragariaPrefsAutoInsertAClosingParenthesis = @"FragariaAutoInsertAClosingParenthesis";
NSString * const MGSFragariaPrefsAutoInsertAClosingBrace = @"FragariaAutoInsertAClosingBrace";
NSString * const MGSFragariaPrefsShowPageGuide = @"FragariaShowPageGuide";

/* integer */
NSString * const MGSFragariaPrefsGutterWidth = @"FragariaGutterWidth";
NSString * const MGSFragariaPrefsTabWidth = @"FragariaTabWidth";
NSString * const MGSFragariaPrefsIndentWidth = @"FragariaIndentWidth";
NSString * const MGSFragariaPrefsShowPageGuideAtColumn = @"FragariaShowPageGuideAtColumn";

/* float */
NSString * const MGSFragariaPrefsAutocompleteAfterDelay = @"FragariaAutocompleteAfterDelay";

/* archived font */
NSString * const MGSFragariaPrefsTextFont = @"FragariaTextFont";

/* colour scheme plist */
NSString * const MGSFragariaPrefsLightColourScheme = @"FragariaColourScheme_Light";
NSString * const MGSFragariaPrefsDarkColourScheme = @"FragariaColourScheme_Dark";


/** OLD **/

/* archived colour */
NSString * const MGSFragariaPrefsCommandsColourWell = @"FragariaCommandsColourWell";
NSString * const MGSFragariaPrefsCommentsColourWell = @"FragariaCommentsColourWell";
NSString * const MGSFragariaPrefsInstructionsColourWell = @"FragariaInstructionsColourWell";
NSString * const MGSFragariaPrefsKeywordsColourWell = @"FragariaKeywordsColourWell";
NSString * const MGSFragariaPrefsAutocompleteColourWell = @"FragariaAutocompleteColourWell";
NSString * const MGSFragariaPrefsVariablesColourWell = @"FragariaVariablesColourWell";
NSString * const MGSFragariaPrefsStringsColourWell = @"FragariaStringsColourWell";
NSString * const MGSFragariaPrefsAttributesColourWell = @"FragariaAttributesColourWell";
NSString * const MGSFragariaPrefsNumbersColourWell = @"FragariaNumbersColourWell";
NSString * const MGSFragariaPrefsBackgroundColourWell = @"FragariaBackgroundColourWell";
NSString * const MGSFragariaPrefsTextColourWell = @"FragariaTextColourWell";
NSString * const MGSFragariaPrefsInvisibleCharactersColourWell = @"FragariaInvisibleCharactersColourWell";
NSString * const MGSFragariaPrefsHighlightLineColourWell = @"FragariaHighlightLineColourWell";

/* bool */
NSString * const MGSFragariaPrefsColourNumbers = @"FragariaColourNumbers";
NSString * const MGSFragariaPrefsColourCommands = @"FragariaColourCommands";
NSString * const MGSFragariaPrefsColourComments = @"FragariaColourComments";
NSString * const MGSFragariaPrefsColourInstructions = @"FragariaColourInstructions";
NSString * const MGSFragariaPrefsColourKeywords = @"FragariaColourKeywords";
NSString * const MGSFragariaPrefsColourAutocomplete = @"FragariaColourAutocomplete";
NSString * const MGSFragariaPrefsColourVariables = @"FragariaColourVariables";
NSString * const MGSFragariaPrefsColourStrings = @"FragariaColourStrings";
NSString * const MGSFragariaPrefsColourAttributes = @"FragariaColourAttributes";


/* KVO context constants */
static char kc_ContextStart[19];
#define kcBackgroundColorChanged (kc_ContextStart[0])
#define kcColoursChanged (kc_ContextStart[1])
#define kcFragariaTabWidthChanged (kc_ContextStart[3])
#define kcFragariaTextFontChanged (kc_ContextStart[4])
#define kcGutterGutterTextColourWell (kc_ContextStart[5])
#define kcGutterWidthPrefChanged (kc_ContextStart[6])
#define kcInvisibleCharacterValueChanged (kc_ContextStart[7])
#define kcLineHighlightingChanged (kc_ContextStart[8])
#define kcLineNumberPrefChanged (kc_ContextStart[9])
#define kcLineWrapPrefChanged (kc_ContextStart[10])
#define kcMultiLineChanged (kc_ContextStart[11])
#define kcPageGuideChanged (kc_ContextStart[12])
#define kcSyntaxColourPrefChanged (kc_ContextStart[13])
#define kcTextColorChanged (kc_ContextStart[14])
#define kcShowMatchingBracesChanged (kc_ContextStart[15])
#define kcAutoInsertionPrefsChanged (kc_ContextStart[16])
#define kcIndentingPrefsChanged (kc_ContextStart[17])
#define kcAutoCompletePrefsChanged (kc_ContextStart[18])
#define kc_ContextEnd (kc_ContextStart[19])


@implementation MOSFragariaPreferencesObserver


+ (void)load
{
  [self registerFragariaDefaults];
}


- (instancetype)initWithFragaria:(MGSFragariaView *)fragaria
{
  self = [super init];
  _fragaria = fragaria;
  registeredKeyPaths = [[NSMutableArray alloc] init];
  
  [self registerKVO];
  
  return self;
}


- (void)dealloc
{
  NSUserDefaults *ud;
  NSString *keyPath;
  
  ud = [NSUserDefaults standardUserDefaults];
  for (keyPath in registeredKeyPaths) {
    [ud removeObserver:self forKeyPath:keyPath];
  }
  [_fragaria removeObserver:self forKeyPath:NSStringFromSelector(@selector(effectiveAppearance))];
}


#pragma mark - Standard defaults


+ (void)registerFragariaDefaults
{
  [self attemptDefaultsMigration];
  
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSDictionary *defaults;
  
  defaults = [self fragariaDefaultsDictionary];
  [ud registerDefaults:defaults];
}


+ (void)attemptDefaultsMigration
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  if ([ud objectForKey:MGSFragariaPrefsLightColourScheme])
    return;
  
  const NSArray *legacyPropertyList = @[
    MGSFragariaPrefsCommandsColourWell,
    MGSFragariaPrefsCommentsColourWell,
    MGSFragariaPrefsInstructionsColourWell,
    MGSFragariaPrefsKeywordsColourWell,
    MGSFragariaPrefsAutocompleteColourWell,
    MGSFragariaPrefsVariablesColourWell,
    MGSFragariaPrefsStringsColourWell,
    MGSFragariaPrefsAttributesColourWell,
    MGSFragariaPrefsNumbersColourWell,
    MGSFragariaPrefsBackgroundColourWell,
    MGSFragariaPrefsTextColourWell,
    MGSFragariaPrefsInvisibleCharactersColourWell,
    MGSFragariaPrefsHighlightLineColourWell,
    MGSFragariaPrefsColourNumbers,
    MGSFragariaPrefsColourCommands,
    MGSFragariaPrefsColourComments,
    MGSFragariaPrefsColourInstructions,
    MGSFragariaPrefsColourKeywords,
    MGSFragariaPrefsColourAutocomplete,
    MGSFragariaPrefsColourVariables,
    MGSFragariaPrefsColourStrings,
    MGSFragariaPrefsColourAttributes
  ];
  
  BOOL needsUpdate = NO;
  for (NSString *key in legacyPropertyList) {
    if ([ud objectForKey:key]) {
      needsUpdate = YES;
      break;
    }
  }
  if (!needsUpdate)
    return;
  
  MGSMutableColourScheme *newScheme = [[MGSMutableColourScheme alloc] init];
  #define HANDLE_COLOR_KEY(_key, _invoc) do { \
    id value = [ud objectForKey:(_key)]; \
    if (value) { \
      value = [NSUnarchiver unarchiveObjectWithData:value]; \
      _invoc; \
    } \
  } while (0)
  #define HANDLE_BOOL_KEY(_key, _invoc) do { \
    id objvalue = [ud objectForKey:(_key)]; \
    if (objvalue) { \
      BOOL value = [objvalue boolValue]; \
      _invoc; \
    } \
  } while (0)
  HANDLE_COLOR_KEY(MGSFragariaPrefsCommandsColourWell    , [newScheme setColour:value forSyntaxGroup:MGSSyntaxGroupCommand]);
  HANDLE_COLOR_KEY(MGSFragariaPrefsCommentsColourWell    , [newScheme setColour:value forSyntaxGroup:MGSSyntaxGroupComment]);
  HANDLE_COLOR_KEY(MGSFragariaPrefsInstructionsColourWell, [newScheme setColour:value forSyntaxGroup:MGSSyntaxGroupInstruction]);
  HANDLE_COLOR_KEY(MGSFragariaPrefsKeywordsColourWell    , [newScheme setColour:value forSyntaxGroup:MGSSyntaxGroupKeyword]);
  HANDLE_COLOR_KEY(MGSFragariaPrefsAutocompleteColourWell, [newScheme setColour:value forSyntaxGroup:MGSSyntaxGroupAutoComplete]);
  HANDLE_COLOR_KEY(MGSFragariaPrefsVariablesColourWell   , [newScheme setColour:value forSyntaxGroup:MGSSyntaxGroupVariable]);
  HANDLE_COLOR_KEY(MGSFragariaPrefsStringsColourWell     , [newScheme setColour:value forSyntaxGroup:MGSSyntaxGroupString]);
  HANDLE_COLOR_KEY(MGSFragariaPrefsAttributesColourWell  , [newScheme setColour:value forSyntaxGroup:MGSSyntaxGroupAttribute]);
  HANDLE_COLOR_KEY(MGSFragariaPrefsNumbersColourWell     , [newScheme setColour:value forSyntaxGroup:MGSSyntaxGroupNumber]);
  HANDLE_COLOR_KEY(MGSFragariaPrefsBackgroundColourWell  , newScheme.backgroundColor = value);
  HANDLE_COLOR_KEY(MGSFragariaPrefsTextColourWell        , newScheme.textColor = value);
  HANDLE_COLOR_KEY(MGSFragariaPrefsInvisibleCharactersColourWell, newScheme.textInvisibleCharactersColour = value);
  HANDLE_COLOR_KEY(MGSFragariaPrefsHighlightLineColourWell, newScheme.currentLineHighlightColour = value);
  HANDLE_BOOL_KEY (MGSFragariaPrefsColourNumbers         , [newScheme setColours:value syntaxGroup:MGSSyntaxGroupNumber]);
  HANDLE_BOOL_KEY (MGSFragariaPrefsColourCommands        , [newScheme setColours:value syntaxGroup:MGSSyntaxGroupCommand]);
  HANDLE_BOOL_KEY (MGSFragariaPrefsColourInstructions    , [newScheme setColours:value syntaxGroup:MGSSyntaxGroupInstruction]);
  HANDLE_BOOL_KEY (MGSFragariaPrefsColourKeywords        , [newScheme setColours:value syntaxGroup:MGSSyntaxGroupKeyword]);
  HANDLE_BOOL_KEY (MGSFragariaPrefsColourAutocomplete    , [newScheme setColours:value syntaxGroup:MGSSyntaxGroupAutoComplete]);
  HANDLE_BOOL_KEY (MGSFragariaPrefsColourVariables       , [newScheme setColours:value syntaxGroup:MGSSyntaxGroupVariable]);
  HANDLE_BOOL_KEY (MGSFragariaPrefsColourStrings         , [newScheme setColours:value syntaxGroup:MGSSyntaxGroupString]);
  HANDLE_BOOL_KEY (MGSFragariaPrefsColourAttributes      , [newScheme setColours:value syntaxGroup:MGSSyntaxGroupAttribute]);
  HANDLE_BOOL_KEY (MGSFragariaPrefsColourComments        , [newScheme setColours:value syntaxGroup:MGSSyntaxGroupComment]);
  #undef HANDLE_KEY
  
  [ud setObject:newScheme.propertyListRepresentation forKey:MGSFragariaPrefsLightColourScheme];
}


#define ARCHIVED_COLOR(rd, gr, bl) [NSArchiver archivedDataWithRootObject:\
[NSColor colorWithCalibratedRed:rd green:gr blue:bl alpha:1.0f]]
#define ARCHIVED_OBJECT(obj) [NSArchiver archivedDataWithRootObject:obj]

+ (NSDictionary *)fragariaDefaultsDictionary
{
  MGSColourScheme *darkDefault;
  if (@available(macOS 10.14, *)) {
    darkDefault = [MGSColourScheme defaultColorSchemeForAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
  } else {
    darkDefault = [[MGSColourScheme alloc] init];
  }
  return @{
    MGSFragariaPrefsGutterTextColourWell: ARCHIVED_COLOR(0.42f, 0.42f, 0.42f),
    MGSFragariaPrefsLightColourScheme: [[MGSColourScheme defaultColorSchemeForAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]] propertyListRepresentation],
    MGSFragariaPrefsDarkColourScheme: [darkDefault propertyListRepresentation],
    MGSFragariaPrefsGutterWidth: @(40),
    MGSFragariaPrefsTabWidth: @(4),
    MGSFragariaPrefsIndentWidth: @(4),
    MGSFragariaPrefsShowPageGuide: @(NO),
    MGSFragariaPrefsShowPageGuideAtColumn: @(80),
    MGSFragariaPrefsAutocompleteAfterDelay: @(1.0),
    MGSFragariaPrefsTextFont: ARCHIVED_OBJECT([NSFont fontWithName:@"Menlo" size:11]),
    MGSFragariaPrefsShowLineNumberGutter: @(YES),
    MGSFragariaPrefsSyntaxColourNewDocuments: @(YES),
    MGSFragariaPrefsLineWrapNewDocuments: @(YES),
    MGSFragariaPrefsIndentNewLinesAutomatically: @(YES),
    MGSFragariaPrefsOnlyColourTillTheEndOfLine: @(YES),
    MGSFragariaPrefsShowMatchingBraces: @(YES),
    MGSFragariaPrefsShowInvisibleCharacters: @(NO),
    MGSFragariaPrefsIndentWithSpaces: @(NO),
    MGSFragariaPrefsColourMultiLineStrings: @(NO),
    MGSFragariaPrefsAutocompleteSuggestAutomatically: @(NO),
    MGSFragariaPrefsAutocompleteIncludeStandardWords: @(NO),
    MGSFragariaPrefsUseTabStops: @(YES),
    MGSFragariaPrefsHighlightCurrentLine: @(NO),
    MGSFragariaPrefsAutomaticallyIndentBraces: @(YES),
    MGSFragariaPrefsAutoInsertAClosingParenthesis: @(NO),
    MGSFragariaPrefsAutoInsertAClosingBrace: @(NO)
  };
}


#pragma mark - Defaults observing


- (void)observeDefault:(NSString*)prop context:(void*)ctxt
{
  [self observeDefaults:@[prop] context:ctxt];
}


- (void)observeDefaults:(NSArray*)arry context:(void*)ctxt
{
  NSUserDefaults *dc = [NSUserDefaults standardUserDefaults];
  NSString *keyPath;
  
  for (NSString *prop in arry) {
    keyPath = [NSString stringWithFormat:@"%@", prop];
    
    [dc addObserver:self forKeyPath:keyPath options:0 context:ctxt];
    [registeredKeyPaths addObject:keyPath];
  }
  [self updateDefaults:ctxt];
}


- (void)registerKVO
{
  // MGSTextView
  [self observeDefault:MGSFragariaPrefsGutterWidth context:&kcGutterWidthPrefChanged];
  [self observeDefault:MGSFragariaPrefsSyntaxColourNewDocuments context:&kcSyntaxColourPrefChanged];
  [self observeDefault:MGSFragariaPrefsShowLineNumberGutter context:&kcLineNumberPrefChanged];
  [self observeDefault:MGSFragariaPrefsLineWrapNewDocuments context:&kcLineWrapPrefChanged];
  [self observeDefault:MGSFragariaPrefsGutterTextColourWell context:&kcGutterGutterTextColourWell];
  [self observeDefault:MGSFragariaPrefsTextFont context:&kcFragariaTextFontChanged];
  [self observeDefault:MGSFragariaPrefsShowInvisibleCharacters context:&kcInvisibleCharacterValueChanged];
  [self observeDefault:MGSFragariaPrefsTabWidth context:&kcFragariaTabWidthChanged];
  [self observeDefault:MGSFragariaPrefsBackgroundColourWell context:&kcBackgroundColorChanged];
  [self observeDefault:MGSFragariaPrefsTextColourWell context:&kcTextColorChanged];
  
  [self observeDefaults:@[MGSFragariaPrefsShowPageGuide, MGSFragariaPrefsShowPageGuideAtColumn]
     context:&kcPageGuideChanged];
  
  [self observeDefault:MGSFragariaPrefsHighlightCurrentLine
    context:&kcLineHighlightingChanged];
  
  [self observeDefault:MGSFragariaPrefsShowMatchingBraces context:&kcShowMatchingBracesChanged];
  
  [self observeDefaults:@[MGSFragariaPrefsAutoInsertAClosingBrace,
    MGSFragariaPrefsAutoInsertAClosingParenthesis] context:&kcAutoInsertionPrefsChanged];
  
  [self observeDefaults:@[MGSFragariaPrefsIndentWithSpaces, MGSFragariaPrefsUseTabStops,
    MGSFragariaPrefsIndentNewLinesAutomatically, MGSFragariaPrefsAutomaticallyIndentBraces]
    context:&kcIndentingPrefsChanged];
  
  [self observeDefaults:@[MGSFragariaPrefsAutocompleteSuggestAutomatically,
    MGSFragariaPrefsAutocompleteAfterDelay, MGSFragariaPrefsAutocompleteIncludeStandardWords]
    context:&kcAutoCompletePrefsChanged];
  
  [self observeDefaults:@[MGSFragariaPrefsColourMultiLineStrings,
    MGSFragariaPrefsOnlyColourTillTheEndOfLine] context:&kcMultiLineChanged];
  
  /* MGSColourScheme */
  [self observeDefaults:@[
    MGSFragariaPrefsLightColourScheme,
    MGSFragariaPrefsDarkColourScheme] context:&kcColoursChanged];
  
  /* appearance change */
  [_fragaria addObserver:self forKeyPath:NSStringFromSelector(@selector(effectiveAppearance)) options:0 context:&kcColoursChanged];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
  change:(NSDictionary *)change context:(void *)context
{
  if (context >= (void*)&kc_ContextStart && context < (void*)&kc_ContextEnd) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self updateDefaults:context];
    });
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}


- (void)updateDefaults:(void*)context
{
  BOOL boolValue;
  NSColor *colorValue;
  NSFont *fontValue;
  MGSFragariaView *f = _fragaria;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
#define UNAR(x) [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:x]]

  if (context == &kcGutterWidthPrefChanged) {
    f.minimumGutterWidth = [defaults doubleForKey:MGSFragariaPrefsGutterWidth];
    
  } else if (context == &kcLineNumberPrefChanged) {
    boolValue = [defaults boolForKey:MGSFragariaPrefsShowLineNumberGutter];
    f.showsGutter = boolValue;
    
  } else if (context == &kcSyntaxColourPrefChanged) {
    boolValue = [defaults boolForKey:MGSFragariaPrefsSyntaxColourNewDocuments];
    f.syntaxColoured = boolValue;
    
  } else if (context == &kcLineWrapPrefChanged) {
    boolValue = [defaults boolForKey:MGSFragariaPrefsLineWrapNewDocuments];
    f.lineWrap = boolValue;
    
  } else if (context == &kcGutterGutterTextColourWell) {
    f.gutterTextColour = UNAR(MGSFragariaPrefsGutterTextColourWell);
  
  } else if (context == &kcInvisibleCharacterValueChanged) {
    f.showsInvisibleCharacters = [defaults boolForKey:MGSFragariaPrefsShowInvisibleCharacters];
    
  } else if (context == &kcFragariaTextFontChanged) {
    fontValue = UNAR(MGSFragariaPrefsTextFont);
    f.textFont = fontValue;   
    f.gutterFont = fontValue;
  
  } else if (context == &kcFragariaTabWidthChanged) {
    f.tabWidth = [defaults integerForKey:MGSFragariaPrefsTabWidth];
    
  } else if (context == &kcShowMatchingBracesChanged) {
    f.showsMatchingBraces = [defaults boolForKey:MGSFragariaPrefsShowMatchingBraces];
    
  } else if (context == &kcAutoInsertionPrefsChanged) {
    f.insertClosingBraceAutomatically = [defaults boolForKey:MGSFragariaPrefsAutoInsertAClosingBrace];
    f.insertClosingParenthesisAutomatically = [defaults boolForKey:MGSFragariaPrefsAutoInsertAClosingParenthesis];
    
  } else if (context == &kcIndentingPrefsChanged) {
    f.indentWithSpaces = [defaults boolForKey:MGSFragariaPrefsIndentWithSpaces];
    f.useTabStops = [defaults boolForKey:MGSFragariaPrefsUseTabStops] ;
    f.indentNewLinesAutomatically = [defaults boolForKey:MGSFragariaPrefsIndentNewLinesAutomatically];
    f.indentBracesAutomatically = [defaults boolForKey:MGSFragariaPrefsAutomaticallyIndentBraces];
    
  } else if (context == &kcBackgroundColorChanged) {
    f.textView.backgroundColor = UNAR(MGSFragariaPrefsBackgroundColourWell);
    
  } else if (context == &kcTextColorChanged) {
    colorValue = UNAR(MGSFragariaPrefsTextColourWell);
    f.textView.insertionPointColor = colorValue;
    f.textView.textColor = colorValue;
    
  } else if (context == &kcPageGuideChanged) {
    f.pageGuideColumn = [defaults integerForKey:MGSFragariaPrefsShowPageGuideAtColumn];
    f.showsPageGuide = [defaults boolForKey:MGSFragariaPrefsShowPageGuide];
    
  } else if (context == &kcLineHighlightingChanged) {
    f.highlightsCurrentLine = [defaults boolForKey:MGSFragariaPrefsHighlightCurrentLine];
    
  } else if (context == &kcMultiLineChanged) {
    f.coloursMultiLineStrings = [defaults boolForKey:MGSFragariaPrefsColourMultiLineStrings];
    f.coloursOnlyUntilEndOfLine = [defaults boolForKey:MGSFragariaPrefsOnlyColourTillTheEndOfLine];
    
  } else if (context == &kcAutoCompletePrefsChanged) {
    f.autoCompleteEnabled = [defaults boolForKey:MGSFragariaPrefsAutocompleteSuggestAutomatically];
    f.autoCompleteDelay = [defaults doubleForKey:MGSFragariaPrefsAutocompleteAfterDelay];
    f.autoCompleteWithKeywords = [defaults boolForKey:MGSFragariaPrefsAutocompleteIncludeStandardWords];
    
  } else if (context == &kcColoursChanged) {
    id colourSchemePlist;
    if (@available(macOS 10.14, *)) {
      NSAppearanceName currAppearance = [[f effectiveAppearance] bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
      if ([currAppearance isEqual:NSAppearanceNameDarkAqua])
        colourSchemePlist = [defaults objectForKey:MGSFragariaPrefsDarkColourScheme];
      else
        colourSchemePlist = [defaults objectForKey:MGSFragariaPrefsLightColourScheme];
    } else {
      colourSchemePlist = [defaults objectForKey:MGSFragariaPrefsLightColourScheme];
    }
  
    MGSColourScheme *cs = [[MGSColourScheme alloc] initWithPropertyList:colourSchemePlist error:nil];
    if (cs)
      f.colourScheme = cs;
  }
}


@end
