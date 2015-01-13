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
  [self setAllowsUndo:NO];
  [self setTeletypeCursorPosition:0];
  
  return self;
}


- (BOOL)shouldDrawInsertionPoint {
  return NO;
}


- (void)setFrameSize:(NSSize)newSize {
  [super setFrameSize:newSize];
  [self setTeletypeCursorPosition:lastCur];
}


- (void)setTeletypeCursorPosition:(NSInteger)cur {
  NSInteger gliph, length, lastcindex;
  NSRect glyphRect, oldRect;
  NSSize spaceSize;
  NSRange gliphRange;
  NSLayoutManager *lm;
  NSTextContainer *tc;
  unichar lastc;
  
  lastCur = cur;
  
  lm = [self layoutManager];
  tc = [self textContainer];
  
  length = [[self textStorage] length];
  if (length == 0) {
    [[[self textStorage] mutableString] appendString:@" "];
    gliph = [lm glyphIndexForCharacterAtIndex:0];
    gliphRange.length = 1;
    gliphRange.location = 0;
    glyphRect = [lm boundingRectForGlyphRange:gliphRange inTextContainer:tc];
    [[[self textStorage] mutableString] setString:@""];
  } else {
    if (cur >= length)
      lastcindex = length-1;
    else
      lastcindex = cur;
      
    gliph = [lm glyphIndexForCharacterAtIndex:lastcindex];
    lastc = [[[self textStorage] mutableString] characterAtIndex:lastcindex];

    gliphRange.length = 1;
    gliphRange.location = gliph;
    glyphRect = [lm boundingRectForGlyphRange:gliphRange inTextContainer:tc];
    
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastc]) {
      glyphRect.size.height /= 2;
      glyphRect.origin.y += glyphRect.size.height;
      glyphRect.origin.x += [tc lineFragmentPadding];
      glyphRect.size.width = 0;
    }
    
    if (cur >= length) {
      spaceSize = [@" " sizeWithAttributes:@{NSFontAttributeName: [self font]}];
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


- (void)setTeletypeFormat {
  NSMutableParagraphStyle *parstyle;
  NSMutableDictionary *attributes;
  NSRange all;
  
  all.location = 0;
  all.length = [[self textStorage] length];
  parstyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  [parstyle setLineBreakMode:NSLineBreakByCharWrapping];
  attributes = [NSMutableDictionary dictionary];
  [attributes setObject:[parstyle copy] forKey:NSParagraphStyleAttributeName];
  [attributes setObject:[self font] forKey:NSFontAttributeName];
  [[self textStorage] setAttributes:[attributes copy] range:all];
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


- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
  if ([anItem action] == @selector(cut:)) return NO;
  return YES;
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
