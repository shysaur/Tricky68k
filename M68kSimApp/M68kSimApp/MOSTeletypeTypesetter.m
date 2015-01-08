//
//  MOSTeletypeTypesetter.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 08/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSTeletypeTypesetter.h"


@implementation MOSTeletypeTypesetter


- (UTF32Char)hyphenCharacterForGlyphAtIndex:(NSUInteger)glyphIndex {
  return 0x2060;
}


- (float)hyphenationFactorForGlyphAtIndex:(NSUInteger)glyphIndex {
  return 1.0;
}


- (BOOL)shouldBreakLineByHyphenatingBeforeCharacterAtIndex:(NSUInteger)charIndex {
  return YES;
}


- (BOOL)shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex {
  return NO;
}


@end
