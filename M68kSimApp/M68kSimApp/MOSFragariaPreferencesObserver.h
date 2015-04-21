//
//  MGSTemporaryPreferencesObserver.h
//  Fragaria
//
//  Created by Jim Derry on 2/27/15.
//
//

#import <Cocoa/Cocoa.h>

@class MGSFragaria;


extern NSString * const MGSFragariaPrefsCommandsColourWell;
extern NSString * const MGSFragariaPrefsCommentsColourWell;
extern NSString * const MGSFragariaPrefsInstructionsColourWell;
extern NSString * const MGSFragariaPrefsKeywordsColourWell;
extern NSString * const MGSFragariaPrefsAutocompleteColourWell;
extern NSString * const MGSFragariaPrefsVariablesColourWell;
extern NSString * const MGSFragariaPrefsStringsColourWell;
extern NSString * const MGSFragariaPrefsAttributesColourWell;
extern NSString * const MGSFragariaPrefsBackgroundColourWell;
extern NSString * const MGSFragariaPrefsTextColourWell;
extern NSString * const MGSFragariaPrefsGutterTextColourWell;
extern NSString * const MGSFragariaPrefsInvisibleCharactersColourWell;
extern NSString * const MGSFragariaPrefsHighlightLineColourWell;
extern NSString * const MGSFragariaPrefsNumbersColourWell;

extern NSString * const MGSFragariaPrefsColourNumbers;
extern NSString * const MGSFragariaPrefsColourCommands;
extern NSString * const MGSFragariaPrefsColourComments;
extern NSString * const MGSFragariaPrefsColourInstructions;
extern NSString * const MGSFragariaPrefsColourKeywords;
extern NSString * const MGSFragariaPrefsColourAutocomplete;
extern NSString * const MGSFragariaPrefsColourVariables;
extern NSString * const MGSFragariaPrefsColourStrings;
extern NSString * const MGSFragariaPrefsColourAttributes;

extern NSString * const MGSFragariaPrefsShowLineNumberGutter;
extern NSString * const MGSFragariaPrefsSyntaxColourNewDocuments;
extern NSString * const MGSFragariaPrefsLineWrapNewDocuments;
extern NSString * const MGSFragariaPrefsIndentNewLinesAutomatically;
extern NSString * const MGSFragariaPrefsOnlyColourTillTheEndOfLine;
extern NSString * const MGSFragariaPrefsShowMatchingBraces;
extern NSString * const MGSFragariaPrefsShowInvisibleCharacters;
extern NSString * const MGSFragariaPrefsIndentWithSpaces;
extern NSString * const MGSFragariaPrefsColourMultiLineStrings;
extern NSString * const MGSFragariaPrefsAutocompleteSuggestAutomatically;
extern NSString * const MGSFragariaPrefsAutocompleteIncludeStandardWords;
extern NSString * const MGSFragariaPrefsUseTabStops;
extern NSString * const MGSFragariaPrefsHighlightCurrentLine;
extern NSString * const MGSFragariaPrefsAutomaticallyIndentBraces;
extern NSString * const MGSFragariaPrefsAutoInsertAClosingParenthesis;
extern NSString * const MGSFragariaPrefsAutoInsertAClosingBrace;
extern NSString * const MGSFragariaPrefsShowPageGuide;

extern NSString * const MGSFragariaPrefsGutterWidth;
extern NSString * const MGSFragariaPrefsTabWidth;
extern NSString * const MGSFragariaPrefsIndentWidth;
extern NSString * const MGSFragariaPrefsShowPageGuideAtColumn;

extern NSString * const MGSFragariaPrefsAutocompleteAfterDelay;

extern NSString * const MGSFragariaPrefsTextFont;


@interface MOSFragariaPreferencesObserver : NSObject {
  NSMutableArray *registeredKeyPaths;
  MGSFragariaView *_fragaria;
}

- (instancetype)initWithFragaria:(MGSFragariaView *)fragaria;

@end


