//
//  MGSTemporaryPreferencesObserver.m
//  Fragaria
//
//  Created by Jim Derry on 2/27/15.
//
//

#import <Cocoa/Cocoa.h>
#import <MGSFragaria/MGSFragaria.h>
#import "MGSFragariaPreferences.h"
#import "MGSPreferencesObserver.h"


// KVO context constants
static char kcBackgroundColorChanged;
static char kcColoursChanged;
static char kcFragariaInvisibleCharactersColourWellChanged;
static char kcFragariaTabWidthChanged;
static char kcFragariaTextFontChanged;
static char kcGutterGutterTextColourWell;
static char kcGutterWidthPrefChanged;
static char kcInvisibleCharacterValueChanged;
static char kcLineHighlightingChanged;
static char kcLineNumberPrefChanged;
static char kcLineWrapPrefChanged;
static char kcMultiLineChanged;
static char kcPageGuideChanged;
static char kcSyntaxColourPrefChanged;
static char kcTextColorChanged;
static char kcShowMatchingBracesChanged;
static char kcAutoInsertionPrefsChanged;
static char kcIndentingPrefsChanged;
static char kcAutoCompletePrefsChanged;


@interface MGSPreferencesObserver ()

@property (nonatomic, weak) MGSFragariaView *fragaria;

@end


@implementation MGSPreferencesObserver {
    NSMutableArray *registeredKeyPaths;
}


/*
 *  - initWithFragaria:
 */
- (instancetype)initWithFragaria:(MGSFragariaView *)fragaria
{
    static dispatch_once_t onceToken;

    if ((self = [super init]))
    {
        self.fragaria = fragaria;
        registeredKeyPaths = [[NSMutableArray alloc] init];
        
        /* Avoid registering Fragaria's standard defaults if this class
         * is not used */
        dispatch_once(&onceToken, ^{
            [self registerFragariaDefaults];
        });
        
        [self registerKVO];
    }
	
    return self;
}


/*
 * - dealloc
 */
-(void)dealloc
{
    NSUserDefaultsController *defaultsController;
    NSString *keyPath;
    
    defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    for (keyPath in registeredKeyPaths) {
        [defaultsController removeObserver:self forKeyPath:keyPath];
    }
}


#pragma mark - Standard defaults


- (void)registerFragariaDefaults
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
    NSDictionary *defaults;
    NSMutableDictionary *tmp;
    
    defaults = [MGSPreferencesObserver fragariaDefaultsDictionary];
    
    tmp = [[udc initialValues] mutableCopy];
    if (tmp) {
        [tmp addEntriesFromDictionary:defaults];
        [udc setInitialValues:tmp];
    } else {
        [udc setInitialValues:defaults];
    }
    
    [ud registerDefaults:defaults];
}


#define ARCHIVED_COLOR(rd, gr, bl) [NSArchiver archivedDataWithRootObject:\
  [NSColor colorWithCalibratedRed:rd green:gr blue:bl alpha:1.0f]]
#define ARCHIVED_OBJECT(obj) [NSArchiver archivedDataWithRootObject:obj]

/*
 *  @property fragariaDefaultsDictionary
 */
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
        MGSFragariaPrefsGutterTextColourWell: ARCHIVED_OBJECT([NSColor colorWithCalibratedWhite:0.42f alpha:1.0f]),
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


/*
 * - observeDefault: context:
 */
- (void)observeDefault:(NSString*)prop context:(void*)ctxt
{
    [self observeDefaults:@[prop] context:ctxt];
}


/* 
 * - observeDefaults: context:
 */
- (void)observeDefaults:(NSArray*)arry context:(void*)ctxt
{
    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSString *keyPath;
    NSUInteger i;
    NSKeyValueObservingOptions opts;
    
    i = 1;
    for (NSString *prop in arry) {
        keyPath = [NSString stringWithFormat:@"values.%@", prop];
        
        opts = (i == [arry count]) ? NSKeyValueObservingOptionInitial : 0;
        [defaultsController addObserver:self forKeyPath:keyPath options:opts context:ctxt];
        [registeredKeyPaths addObject:keyPath];
        i++;
    }
}


/*
 *  - registerKVO
 */
-(void)registerKVO
{
    // SMLTextView
    [self observeDefault:MGSFragariaPrefsGutterWidth context:&kcGutterWidthPrefChanged];
    [self observeDefault:MGSFragariaPrefsSyntaxColourNewDocuments context:&kcSyntaxColourPrefChanged];
    [self observeDefault:MGSFragariaPrefsShowLineNumberGutter context:&kcLineNumberPrefChanged];
    [self observeDefault:MGSFragariaPrefsLineWrapNewDocuments context:&kcLineWrapPrefChanged];
    [self observeDefault:MGSFragariaPrefsGutterTextColourWell context:&kcGutterGutterTextColourWell];
    [self observeDefault:MGSFragariaPrefsTextFont context:&kcFragariaTextFontChanged];
    [self observeDefault:MGSFragariaPrefsInvisibleCharactersColourWell context:&kcFragariaInvisibleCharactersColourWellChanged];
    [self observeDefault:MGSFragariaPrefsShowInvisibleCharacters context:&kcInvisibleCharacterValueChanged];
    [self observeDefault:MGSFragariaPrefsTabWidth context:&kcFragariaTabWidthChanged];
    [self observeDefault:MGSFragariaPrefsBackgroundColourWell context:&kcBackgroundColorChanged];
    [self observeDefault:MGSFragariaPrefsTextColourWell context:&kcTextColorChanged];
    
    [self observeDefaults:@[MGSFragariaPrefsShowPageGuide, MGSFragariaPrefsShowPageGuideAtColumn] context:&kcPageGuideChanged];
    
    [self observeDefaults:@[MGSFragariaPrefsHighlightCurrentLine, MGSFragariaPrefsHighlightLineColourWell] context:&kcLineHighlightingChanged];
    
    [self observeDefault:MGSFragariaPrefsShowMatchingBraces context:&kcShowMatchingBracesChanged];
    
    [self observeDefaults:@[MGSFragariaPrefsAutoInsertAClosingBrace, MGSFragariaPrefsAutoInsertAClosingParenthesis] context:&kcAutoInsertionPrefsChanged];
    
    [self observeDefaults:@[MGSFragariaPrefsIndentWithSpaces, MGSFragariaPrefsUseTabStops, MGSFragariaPrefsIndentNewLinesAutomatically, MGSFragariaPrefsAutomaticallyIndentBraces] context:&kcIndentingPrefsChanged];
    
    [self observeDefaults:@[MGSFragariaPrefsAutocompleteSuggestAutomatically, MGSFragariaPrefsAutocompleteAfterDelay, MGSFragariaPrefsAutocompleteIncludeStandardWords] context:&kcAutoCompletePrefsChanged];

	// SMLSyntaxColouring
	[self observeDefaults:@[
      MGSFragariaPrefsCommandsColourWell,     MGSFragariaPrefsCommentsColourWell,
      MGSFragariaPrefsInstructionsColourWell, MGSFragariaPrefsKeywordsColourWell,
      MGSFragariaPrefsAutocompleteColourWell, MGSFragariaPrefsVariablesColourWell,
      MGSFragariaPrefsStringsColourWell,      MGSFragariaPrefsAttributesColourWell,
      MGSFragariaPrefsNumbersColourWell,
	  MGSFragariaPrefsColourCommands,     MGSFragariaPrefsColourComments,
      MGSFragariaPrefsColourInstructions, MGSFragariaPrefsColourKeywords,
      MGSFragariaPrefsColourAutocomplete, MGSFragariaPrefsColourVariables,
      MGSFragariaPrefsColourStrings,      MGSFragariaPrefsColourAttributes,
      MGSFragariaPrefsColourNumbers] context:&kcColoursChanged];
	
	[self observeDefaults:@[MGSFragariaPrefsColourMultiLineStrings, MGSFragariaPrefsOnlyColourTillTheEndOfLine] context:&kcMultiLineChanged];
}


/*
 *  - observerValueForKeyPath:ofObject:change:context
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    BOOL boolValue;
    NSColor *colorValue;
    NSFont *fontValue;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (context == &kcGutterWidthPrefChanged)
    {
        self.fragaria.minimumGutterWidth = [defaults doubleForKey:MGSFragariaPrefsGutterWidth];
    }
    else if (context == &kcLineNumberPrefChanged)
    {
        boolValue = [defaults boolForKey:MGSFragariaPrefsShowLineNumberGutter];
        self.fragaria.showsGutter = boolValue;
    }
    else if (context == &kcSyntaxColourPrefChanged)
    {
        boolValue = [defaults boolForKey:MGSFragariaPrefsSyntaxColourNewDocuments];
        self.fragaria.syntaxColoured = boolValue;
    }
    else if (context == &kcLineWrapPrefChanged)
    {
        boolValue = [defaults boolForKey:MGSFragariaPrefsLineWrapNewDocuments];
        self.fragaria.lineWrap = boolValue;
    }
    else if (context == &kcGutterGutterTextColourWell)
    {
        self.fragaria.gutterTextColour = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsGutterTextColourWell]];
    }
    else if (context == &kcInvisibleCharacterValueChanged)
    {
        self.fragaria.showsInvisibleCharacters = [defaults boolForKey:MGSFragariaPrefsShowInvisibleCharacters];
    }
    else if (context == &kcFragariaTextFontChanged)
    {
        fontValue = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsTextFont]];
        self.fragaria.textFont = fontValue;   // these won't always be tied together, but this is current behavior.
        self.fragaria.gutterFont = fontValue; // these won't always be tied together, but this is current behavior.
    }
    else if (context == &kcFragariaInvisibleCharactersColourWellChanged)
    {
        self.fragaria.textInvisibleCharactersColour = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsInvisibleCharactersColourWell]];
    }
    else if (context == &kcFragariaTabWidthChanged)
    {
        self.fragaria.tabWidth = [defaults integerForKey:MGSFragariaPrefsTabWidth];
    }
    else if (context == &kcShowMatchingBracesChanged)
    {
        self.fragaria.showsMatchingBraces = [defaults boolForKey:MGSFragariaPrefsShowMatchingBraces];
    }
    else if (context == &kcAutoInsertionPrefsChanged)
    {
        self.fragaria.insertClosingBraceAutomatically = [defaults boolForKey:MGSFragariaPrefsAutoInsertAClosingBrace];
        self.fragaria.insertClosingParenthesisAutomatically = [defaults boolForKey:MGSFragariaPrefsAutoInsertAClosingParenthesis];
    }
    else if (context == &kcIndentingPrefsChanged)
    {
        self.fragaria.indentWithSpaces = [defaults boolForKey:MGSFragariaPrefsIndentWithSpaces];
        self.fragaria.useTabStops = [defaults boolForKey:MGSFragariaPrefsUseTabStops] ;
        self.fragaria.indentNewLinesAutomatically = [defaults boolForKey:MGSFragariaPrefsIndentNewLinesAutomatically];
        self.fragaria.indentBracesAutomatically = [defaults boolForKey:MGSFragariaPrefsAutomaticallyIndentBraces];
    }
    else if (context == &kcBackgroundColorChanged)
    {
        self.fragaria.textView.backgroundColor = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsBackgroundColourWell]];
    }
    else if (context == &kcTextColorChanged)
    {
        colorValue = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsTextColourWell]];
        self.fragaria.textView.insertionPointColor = colorValue;
        self.fragaria.textView.textColor = colorValue;
    }
    else if (context == &kcPageGuideChanged)
    {
        self.fragaria.pageGuideColumn = [defaults integerForKey:MGSFragariaPrefsShowPageGuideAtColumn];
        self.fragaria.showsPageGuide = [defaults boolForKey:MGSFragariaPrefsShowPageGuide];
    }
    else if (context == &kcLineHighlightingChanged)
    {
        self.fragaria.highlightsCurrentLine = [defaults boolForKey:MGSFragariaPrefsHighlightCurrentLine];
        self.fragaria.currentLineHighlightColour = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsHighlightLineColourWell]];
    }
    else if (context == &kcMultiLineChanged)
    {
        self.fragaria.coloursMultiLineStrings = [defaults boolForKey:MGSFragariaPrefsColourMultiLineStrings];
        self.fragaria.coloursOnlyUntilEndOfLine = [defaults boolForKey:MGSFragariaPrefsOnlyColourTillTheEndOfLine];
    }
    else if (context == &kcAutoCompletePrefsChanged)
    {
        self.fragaria.autoCompleteEnabled = [defaults boolForKey:MGSFragariaPrefsAutocompleteSuggestAutomatically];
        self.fragaria.autoCompleteDelay = [defaults doubleForKey:MGSFragariaPrefsAutocompleteAfterDelay];
        self.fragaria.autoCompleteWithKeywords = [defaults boolForKey:MGSFragariaPrefsAutocompleteIncludeStandardWords];
    }
    else if (context == &kcColoursChanged)
    {
        MGSFragariaView *sc = self.fragaria;
        
        sc.coloursAttributes = [defaults boolForKey:MGSFragariaPrefsColourAttributes];
        sc.coloursAutocomplete = [defaults boolForKey:MGSFragariaPrefsColourAutocomplete];
        sc.coloursCommands = [defaults boolForKey:MGSFragariaPrefsColourCommands];
        sc.coloursComments = [defaults boolForKey:MGSFragariaPrefsColourComments];
        sc.coloursInstructions = [defaults boolForKey:MGSFragariaPrefsColourInstructions];
        sc.coloursKeywords = [defaults boolForKey:MGSFragariaPrefsColourKeywords];
        sc.coloursNumbers = [defaults boolForKey:MGSFragariaPrefsColourNumbers];
        sc.coloursStrings = [defaults boolForKey:MGSFragariaPrefsColourStrings];
        sc.coloursVariables = [defaults boolForKey:MGSFragariaPrefsColourVariables];
        sc.colourForAttributes = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsAttributesColourWell]];
        sc.colourForAutocomplete = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsAutocompleteColourWell]];
        sc.colourForCommands = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsCommandsColourWell]];
        sc.colourForComments = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsCommentsColourWell]];
        sc.colourForInstructions = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsInstructionsColourWell]];
        sc.colourForKeywords = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsKeywordsColourWell]];
        sc.colourForNumbers = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsNumbersColourWell]];
        sc.colourForStrings = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsStringsColourWell]];
        sc.colourForVariables = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:MGSFragariaPrefsVariablesColourWell]];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


@end
