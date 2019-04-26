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
NSString * const MGSFragariaPrefsGutterTextColourWell = @"FragariaGutterTextColourWell";
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


- (instancetype)initWithFragaria:(MGSFragariaView *)fragaria
{
  static dispatch_once_t onceToken;
  
  self = [super init];
  _fragaria = fragaria;
  registeredKeyPaths = [[NSMutableArray alloc] init];
  
  dispatch_once(&onceToken, ^{
    [self registerFragariaDefaults];
  });
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
}


#pragma mark - Standard defaults


- (void)registerFragariaDefaults
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSDictionary *defaults;
  
  defaults = [MOSFragariaPreferencesObserver fragariaDefaultsDictionary];
  [ud registerDefaults:defaults];
}


#define ARCHIVED_COLOR(rd, gr, bl) [NSArchiver archivedDataWithRootObject:\
[NSColor colorWithCalibratedRed:rd green:gr blue:bl alpha:1.0f]]
#define ARCHIVED_OBJECT(obj) [NSArchiver archivedDataWithRootObject:obj]

+ (NSDictionary *)fragariaDefaultsDictionary
{
  return @{
    MGSFragariaPrefsCommandsColourWell: ARCHIVED_COLOR(0.031f, 0.0f, 0.855f),
    MGSFragariaPrefsCommentsColourWell: ARCHIVED_COLOR(0.0f, 0.45f, 0.0f),
    MGSFragariaPrefsInstructionsColourWell: ARCHIVED_COLOR(0.737f, 0.0f, 0.647f),
    MGSFragariaPrefsKeywordsColourWell: ARCHIVED_COLOR(0.737f, 0.0f, 0.647f),
    MGSFragariaPrefsAutocompleteColourWell: ARCHIVED_COLOR(0.84f, 0.41f, 0.006f),
    MGSFragariaPrefsVariablesColourWell: ARCHIVED_COLOR(0.73f, 0.0f, 0.74f),
    MGSFragariaPrefsStringsColourWell: ARCHIVED_COLOR(0.804f, 0.071f, 0.153f),
    MGSFragariaPrefsAttributesColourWell: ARCHIVED_COLOR(0.50f, 0.5f, 0.2f),
    MGSFragariaPrefsNumbersColourWell: ARCHIVED_COLOR(0.031f, 0.0f, 0.855f),
    MGSFragariaPrefsColourNumbers: @(YES),
    MGSFragariaPrefsColourCommands: @(YES),
    MGSFragariaPrefsColourInstructions: @(YES),
    MGSFragariaPrefsColourKeywords: @(YES),
    MGSFragariaPrefsColourAutocomplete: @(NO),
    MGSFragariaPrefsColourVariables: @(YES),
    MGSFragariaPrefsColourStrings: @(YES),
    MGSFragariaPrefsColourAttributes: @(YES),
    MGSFragariaPrefsColourComments: @(YES),
    MGSFragariaPrefsBackgroundColourWell: ARCHIVED_OBJECT([NSColor whiteColor]),
    MGSFragariaPrefsTextColourWell: ARCHIVED_OBJECT([NSColor textColor]),
    MGSFragariaPrefsGutterTextColourWell: ARCHIVED_COLOR(0.42f, 0.42f, 0.42f),
    MGSFragariaPrefsInvisibleCharactersColourWell: ARCHIVED_OBJECT([NSColor orangeColor]),
    MGSFragariaPrefsHighlightLineColourWell: ARCHIVED_COLOR(0.96f, 0.96f, 0.71f),
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


- (void)registerKVO {
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
  
  /* MGSColourScheme */
  [self observeDefaults:@[
    MGSFragariaPrefsInvisibleCharactersColourWell,
    MGSFragariaPrefsHighlightLineColourWell,
    MGSFragariaPrefsCommandsColourWell,
    MGSFragariaPrefsInstructionsColourWell, MGSFragariaPrefsKeywordsColourWell,
    MGSFragariaPrefsAutocompleteColourWell, MGSFragariaPrefsVariablesColourWell,
    MGSFragariaPrefsStringsColourWell,      MGSFragariaPrefsAttributesColourWell,
    MGSFragariaPrefsNumbersColourWell,      MGSFragariaPrefsCommentsColourWell,
    MGSFragariaPrefsColourCommands,     MGSFragariaPrefsColourComments,
    MGSFragariaPrefsColourInstructions, MGSFragariaPrefsColourKeywords,
    MGSFragariaPrefsColourAutocomplete, MGSFragariaPrefsColourVariables,
    MGSFragariaPrefsColourStrings,      MGSFragariaPrefsColourAttributes,
    MGSFragariaPrefsColourNumbers] context:&kcColoursChanged];
  
  [self observeDefaults:@[MGSFragariaPrefsColourMultiLineStrings,
    MGSFragariaPrefsOnlyColourTillTheEndOfLine] context:&kcMultiLineChanged];
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
    MGSMutableColourScheme *cs = [f.colourScheme mutableCopy];
    cs.currentLineHighlightColour = UNAR(MGSFragariaPrefsHighlightLineColourWell);
    cs.textInvisibleCharactersColour = UNAR(MGSFragariaPrefsInvisibleCharactersColourWell);
    [cs setColours:[defaults boolForKey:MGSFragariaPrefsColourAttributes] syntaxGroup:MGSSyntaxGroupAttribute];
    [cs setColours:[defaults boolForKey:MGSFragariaPrefsColourAutocomplete] syntaxGroup:MGSSyntaxGroupAutoComplete];
    [cs setColours:[defaults boolForKey:MGSFragariaPrefsColourCommands] syntaxGroup:MGSSyntaxGroupCommand];
    [cs setColours:[defaults boolForKey:MGSFragariaPrefsColourComments] syntaxGroup:MGSSyntaxGroupComment];
    [cs setColours:[defaults boolForKey:MGSFragariaPrefsColourInstructions] syntaxGroup:MGSSyntaxGroupInstruction];
    [cs setColours:[defaults boolForKey:MGSFragariaPrefsColourKeywords] syntaxGroup:MGSSyntaxGroupKeyword];
    [cs setColours:[defaults boolForKey:MGSFragariaPrefsColourNumbers] syntaxGroup:MGSSyntaxGroupNumber];
    [cs setColours:[defaults boolForKey:MGSFragariaPrefsColourStrings] syntaxGroup:MGSSyntaxGroupString];
    [cs setColours:[defaults boolForKey:MGSFragariaPrefsColourVariables] syntaxGroup:MGSSyntaxGroupVariable];
    [cs setColour:UNAR(MGSFragariaPrefsAttributesColourWell) forSyntaxGroup:MGSSyntaxGroupAttribute];
    [cs setColour:UNAR(MGSFragariaPrefsAutocompleteColourWell) forSyntaxGroup:MGSSyntaxGroupAutoComplete];
    [cs setColour:UNAR(MGSFragariaPrefsCommandsColourWell) forSyntaxGroup:MGSSyntaxGroupCommand];
    [cs setColour:UNAR(MGSFragariaPrefsCommentsColourWell) forSyntaxGroup:MGSSyntaxGroupComment];
    [cs setColour:UNAR(MGSFragariaPrefsInstructionsColourWell) forSyntaxGroup:MGSSyntaxGroupInstruction];
    [cs setColour:UNAR(MGSFragariaPrefsKeywordsColourWell) forSyntaxGroup:MGSSyntaxGroupKeyword];
    [cs setColour:UNAR(MGSFragariaPrefsNumbersColourWell) forSyntaxGroup:MGSSyntaxGroupNumber];
    [cs setColour:UNAR(MGSFragariaPrefsStringsColourWell) forSyntaxGroup:MGSSyntaxGroupString];
    [cs setColour:UNAR(MGSFragariaPrefsVariablesColourWell) forSyntaxGroup:MGSSyntaxGroupVariable];
    f.colourScheme = cs;
  
  }
}


@end
