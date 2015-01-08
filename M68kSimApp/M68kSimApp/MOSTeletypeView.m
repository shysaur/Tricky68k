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


- init {
  self = [super init];
  
  [self setContinuousSpellCheckingEnabled:NO];
  [self setAllowsUndo:NO];
  [self setTeletypeCursorPosition:0];
  
  return self;
}


- (BOOL)shouldDrawInsertionPoint {
  return NO;
}


- (void)setTeletypeCursorPosition:(NSInteger)cur {
  NSInteger gliph;
  NSRect glyphRect, oldRect;
  NSRange gliphRange, charRange;
  NSLayoutManager *lm;
  NSTextContainer *tc;
  NSAttributedString *space;
  
  lm = [self layoutManager];
  tc = [self textContainer];
  if (cur == [[self textStorage] length]) {
    space = [[NSAttributedString alloc] initWithString:@"\u2060 "];
    [[self textStorage] appendAttributedString:space];
    charRange.location = cur;
    charRange.length = 2;
    gliph = [lm glyphIndexForCharacterAtIndex:cur+1];
    gliphRange.length = 1;
    gliphRange.location = gliph;
    glyphRect = [lm boundingRectForGlyphRange:gliphRange inTextContainer:tc];
    [[self textStorage] replaceCharactersInRange:charRange withString:@""];
  } else {
    gliph = [lm glyphIndexForCharacterAtIndex:cur];
    gliphRange.length = 1;
    gliphRange.location = gliph;
    glyphRect = [lm boundingRectForGlyphRange:gliphRange inTextContainer:tc];
  }
  
  oldRect = curRect;
  curRect = glyphRect;
  [self setNeedsDisplayInRect:oldRect];
  [self setNeedsDisplayInRect:curRect];
  [self scrollRangeToVisible:NSMakeRange(cur, 0)];
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
  if ([anItem action] == @selector(cut:)) return NO;
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
