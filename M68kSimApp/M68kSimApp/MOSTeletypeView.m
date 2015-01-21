//
//  MOSTeletypeView.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSTeletypeView.h"
#import "MOSTeletypeViewDelegate.h"


@implementation MOSTeletypeView


- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  
  lastCur = 0;
  [self setContinuousSpellCheckingEnabled:NO];
  [self setGrammarCheckingEnabled:NO];
  [self setAllowsUndo:NO];
  [self setUsesFontPanel:NO];
  [self setAutomaticTextReplacementEnabled:NO];
  [self setAutomaticSpellingCorrectionEnabled:NO];
  [self setAutomaticQuoteSubstitutionEnabled:NO];
  [self setAutomaticLinkDetectionEnabled:NO];
  [self setAutomaticDataDetectionEnabled:NO];
  [self setAutomaticDashSubstitutionEnabled:NO];
  [self setEnabledTextCheckingTypes:0];
  [self setTeletypeCursorPosition:0];
  
  return self;
}


- (void)setDelegate:(MOSTeletypeViewDelegate<NSTextViewDelegate>*)delegate {
  [super setDelegate:delegate];
  [self setTeletypeFont:[delegate defaultMonospacedFont]];
}


- (BOOL)shouldDrawInsertionPoint {
  return NO;
}


- (void)setFrameSize:(NSSize)newSize {
  [super setFrameSize:newSize];
  [self setTeletypeCursorPosition:lastCur];
}


- (void)setTeletypeCursorPosition:(NSInteger)cur {
  NSInteger glyph, length, lastcindex;
  NSRect glyphRect, oldRect;
  NSSize spaceSize;
  NSRange glyphRange;
  NSLayoutManager *lm;
  NSTextContainer *tc;
  unichar lastc;
  NSAttributedString *space;
  
  lastCur = cur;
  
  lm = [self layoutManager];
  tc = [self textContainer];
  
  length = [[self textStorage] length];
  if (length == 0) {
    space = [[NSAttributedString alloc] initWithString:@" " attributes:ttyAttributes];
    [[self textStorage] appendAttributedString:space];
    glyphRange.length = 1;
    glyphRange.location = 0;
    glyphRect = [lm boundingRectForGlyphRange:glyphRange inTextContainer:tc];
    [[[self textStorage] mutableString] setString:@""];
  } else {
    if (cur >= length)
      lastcindex = length-1;
    else
      lastcindex = cur;
      
    glyph = [lm glyphIndexForCharacterAtIndex:lastcindex];
    lastc = [[[self textStorage] mutableString] characterAtIndex:lastcindex];

    glyphRange.length = 1;
    glyphRange.location = glyph;
    glyphRect = [lm boundingRectForGlyphRange:glyphRange inTextContainer:tc];
    
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastc]) {
      glyphRect.size.height /= 2;
      glyphRect.origin.y += glyphRect.size.height;
      glyphRect.origin.x += [tc lineFragmentPadding];
      glyphRect.size.width = 0;
    }
    
    if (cur >= length) {
      spaceSize = [@" " sizeWithAttributes:ttyAttributes];
      glyphRect.origin.x += glyphRect.size.width;
      glyphRect.size.width = spaceSize.width;
    }
  }

  oldRect = curRect;
  curRect = glyphRect;
  [self setNeedsDisplayInRect:oldRect];
  [self setNeedsDisplayInRect:curRect];
  [self scrollRangeToVisible:NSMakeRange(cur, 0)];
}


- (void)setTeletypeFont:(NSFont*)font {
  NSMutableParagraphStyle *parstyle;
  
  parstyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  [parstyle setLineBreakMode:NSLineBreakByCharWrapping];
  
  ttyAttributes = @{
    NSParagraphStyleAttributeName:[parstyle copy],
    NSFontAttributeName:font };
  
  [self setTeletypeFormat];
  [self setTeletypeCursorPosition:lastCur];
}


- (void)setTeletypeFormat {
  NSRange all;
  
  all.location = 0;
  all.length = [[self textStorage] length];
  [[self textStorage] setAttributes:ttyAttributes range:all];
}


- (void)drawViewBackgroundInRect:(NSRect)rect {
  NSBezierPath *cursor;
  
  [super drawViewBackgroundInRect:rect];
  if (NSIntersectsRect(rect, curRect)) {
    cursor = [NSBezierPath bezierPathWithRect:curRect];
    [[NSColor colorWithCalibratedWhite:.5f alpha:1] setFill];
    [cursor fill];
  }
}


- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {
  if ([anItem action] != @selector(copy:) &&
      [anItem action] != @selector(paste:)) return NO;
  return [super validateUserInterfaceItem:anItem];
}


- (void)paste:(id)sender {
  NSPasteboard *pb;
  NSArray *arry;
  NSString *obj;
  
  pb = [NSPasteboard generalPasteboard];
  arry = [pb readObjectsForClasses:@[[NSString class]] options:nil];
  for (obj in arry) {
    [self insertText:obj];
  }
}


- (void)insertText:(id)aString {
  MOSTeletypeViewDelegate *d;
  
  d = [self delegate];
  [d typedString:aString];
}


- (void)deleteBackward:(id)sender {
  MOSTeletypeViewDelegate *d;
  
  d = [self delegate];
  [d deleteCharactersFromCursor:-1];
}


- (void)deleteForward:(id)sender {
  MOSTeletypeViewDelegate *d;
  
  d = [self delegate];
  [d deleteCharactersFromCursor:1];
}


- (void)deleteToBeginningOfLine:(id)sender {
  MOSTeletypeViewDelegate *d;
  
  d = [self delegate];
  [d deleteCharactersFromCursor:-(NSIntegerMax/2)];
}


- (void)deleteToEndOfLine:(id)sender {
  MOSTeletypeViewDelegate *d;
  
  d = [self delegate];
  [d deleteCharactersFromCursor:(NSIntegerMax/2)];
}


- (void)moveLeft:(id)sender {
  MOSTeletypeViewDelegate *d;
  
  d = [self delegate];
  [d moveCursor:-1];
}


- (void)moveRight:(id)sender {
  MOSTeletypeViewDelegate *d;
  
  d = [self delegate];
  [d moveCursor:1];
}


- (void)moveToBeginningOfLine:(id)sender {
  MOSTeletypeViewDelegate *d;
  
  d = [self delegate];
  [d moveCursor:-(NSIntegerMax/2)];
}


- (void)moveToEndOfLine:(id)sender {
  MOSTeletypeViewDelegate *d;
  
  d = [self delegate];
  [d moveCursor:-(NSIntegerMax/2)];
}


@end
