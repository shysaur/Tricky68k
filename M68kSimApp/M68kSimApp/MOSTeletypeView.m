//
//  MOSTeletypeView.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 02/06/15.
//  Copyright (c) 2015 danielecattaneo. All rights reserved.
//

#import "MOSTeletypeView.h"
#import <objc/objc-runtime.h>


@implementation MOSTeletypeView


- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  [self awakeFromNib];
  return self;
}


- (void)awakeFromNib {
  storage = [[NSMutableString alloc] init];
  lineBuffer = [[NSMutableString alloc] init];
  lineRanges = [[NSMutableArray alloc] init];
  [lineRanges addObject:[NSValue valueWithRange:NSMakeRange(0, 0)]];
  lineLocationCache = [[NSMutableDictionary alloc] init];
  
  dispFont = [NSFont userFixedPitchFontOfSize:11.0];
  [self reloadFontInfo];
  [self updateViewHeight];
}


- (void)reloadFontInfo {
  CTFontRef font = (__bridge CTFontRef)(dispFont);
  CGFloat ascent, descent, leading;
  UniChar test[1] = {' '};
  CGGlyph glyphs[1];
  
  CTFontGetGlyphsForCharacters(font, test, glyphs, 1);
  charSize.width = CTFontGetAdvancesForGlyphs(font, kCTFontOrientationHorizontal, glyphs, NULL, 1);
  ascent = CTFontGetAscent(font);
  descent = CTFontGetDescent(font);
  leading = CTFontGetLeading(font);
  charSize.height = ceil(ascent + descent + leading);
  baselineOffset = descent;
  [lineLocationCache removeAllObjects];
}


- (void)resetCursorRects {
  [self addCursorRect:[self visibleRect] cursor:[NSCursor IBeamCursor]];
}


- (BOOL)acceptsFirstResponder {
  return YES;
}


- (NSString *)string {
  return [storage copy];
}


- (void)setString:(NSString *)string {
  storage = [string mutableCopy];
  [lineLocationCache removeAllObjects];
  [self cacheLineRanges];
  [self updateViewHeight];
  [self setNeedsDisplay:YES];
}


- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange {
  if (replacementRange.length == 0 && replacementRange.location >= [storage length])
    [self insertText:aString];
}


- (void)doCommandBySelector:(SEL)aSelector  {
  if ([self respondsToSelector:aSelector])
    ((void (*)(id, SEL, id))objc_msgSend)(self, aSelector, nil);
}


- (void)setMarkedText:(id)aString selectedRange:(NSRange)selectedRange
  replacementRange:(NSRange)replacemenkltRange  { }


- (void)unmarkText { }


- (NSRange)selectedRange {
  return NSMakeRange([storage length], 0);
}


- (NSRange)markedRange  {
  return NSMakeRange(0, 0);
}


- (BOOL)hasMarkedText  {
  return NO;
}


- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange
  actualRange:(NSRangePointer)actualRange  {
  NSRange allText;
  static NSRange adj;
  NSString *res;
  
  allText = NSMakeRange(0, [storage length]);
  
  adj = NSIntersectionRange(aRange, allText);
  if (!NSEqualRanges(aRange, adj) && actualRange)
    actualRange = &adj;
  else
    actualRange = NULL;
  
  res = [storage substringWithRange:adj];
  return [[NSAttributedString alloc] initWithString:res];
}


- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange  {
  actualRange = NULL;
  return NSMakeRect(0,0,0,0);
}


- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint  {
  NSInteger guess, startchar, c;
  NSRange lineRange;
  NSRect lineRect;
  
  guess = [self lineIndexForPoint:aPoint];
  
  aPoint.y -= lineRect.origin.y;
  startchar = aPoint.y / charSize.height;
  c = startchar + aPoint.x / charSize.width;
  
  lineRange = [[lineRanges objectAtIndex:guess] rangeValue];
  if (c > lineRange.length)
    return NSNotFound;
  return lineRange.location + c;
}


- (NSInteger)lineIndexForPoint:(NSPoint)aPoint {
  NSInteger guess, lines;
  NSRect lineRect;
  
  NSAssert(NSPointInRect(aPoint, [self bounds]), @"Given point is outside bounds");
  lines = [lineRanges count];
  
  guess = aPoint.y / charSize.height;
  lineRect = [self rectForLine:guess];
  while (!NSPointInRect(aPoint, lineRect)) {
    if (aPoint.y < lineRect.origin.y) {
      guess = guess / 2;
    } else {
      if (guess == lines - 1) return NSNotFound;
      guess = guess + (lines - guess) / 2;
    }
    lineRect = [self rectForLine:guess];
  }
  return guess;
}


- (NSArray *)validAttributesForMarkedText {
  return @[];
}


- (BOOL)isFlipped {
  return YES;
}


- (void)scrollToEndOfDocument:(id)sender {
  id clipview;
  CGFloat top;
  
  clipview = [self superview];
  if (![clipview isKindOfClass:[NSClipView class]])
    return;
  
  if ([clipview bounds].size.height < [self bounds].size.height) {
    top = [self bounds].size.height - [clipview bounds].size.height;
    [clipview scrollToPoint:NSMakePoint(0, top)];
  }
}


- (void)insertOutputText:(NSString *)text {
  [storage appendString:text];
  [self cacheLineRanges];
  [self updateViewHeight];
  [self scrollToEndOfDocument:nil];
  [self setNeedsDisplay:YES];
}


- (void)deleteBackward:(id)sender {
  if (![lineBuffer length]) {
    NSBeep();
    return;
  }
  
  [storage deleteCharactersInRange:NSMakeRange([storage length]-1, 1)];
  [lineBuffer deleteCharactersInRange:NSMakeRange([lineBuffer length]-1, 1)];
  [self cacheLineRanges];
  [self updateViewHeight];
  [self setNeedsDisplay:YES];
}


- (void)keyDown:(NSEvent *)theEvent {
  [self interpretKeyEvents:@[theEvent]];
}


- (void)insertNewline:(id)sender {
  [self insertText:@"\n"];
}


- (void)insertText:(id)aString {
  NSInteger i, c;
  unichar a;
  
  if ([aString isKindOfClass:[NSAttributedString class]])
    aString = [aString string];
  
  if ((c = [aString length]) > 1) {
    for (i=0; i<c-1; i++)
      [self insertText:[aString substringWithRange:NSMakeRange(i, 1)]];
    aString = [aString substringWithRange:NSMakeRange(i, 1)];
  }
  
  a = [aString characterAtIndex:0];
  if ([[NSCharacterSet newlineCharacterSet] characterIsMember:a]) {
    [self insertOutputText:@"\n"];
    if ([self.delegate respondsToSelector:@selector(typedString:)]) {
      [lineBuffer appendString:@"\n"];
      [self.delegate typedString:[lineBuffer copy]];
    }
    [lineBuffer setString:@""];
  } else {
    [self insertOutputText:aString];
    [lineBuffer appendString:aString];
  }
}


- (void)cacheLineRanges {
  NSUInteger start, end, cend, l;
  
  [lineRanges removeAllObjects];
  start = end = cend = 0;
  l = [storage length];
  
  while (start < l) {
    [storage getLineStart:NULL end:&end contentsEnd:&cend forRange:NSMakeRange(start, 0)];
    [lineRanges addObject:[NSValue valueWithRange:NSMakeRange(start, cend - start)]];
    start = end;
  }
  
  if (end != cend || start == 0)
    [lineRanges addObject:[NSValue valueWithRange:NSMakeRange(start, 0)]];
}


- (void)updateViewHeight {
  NSUInteger i;
  CGFloat h;
  
  i = [lineRanges count] - 1;
  h = [self locationForLine:i].y + [self heightForLine:i];
  if ([[self superview] isKindOfClass:[NSClipView class]]) {
    h = MAX(h, [[self superview] frame].size.height);
  }
  [self setFrameSize:NSMakeSize([self frame].size.width, h)];
}


- (void)setFrame:(NSRect)frame {
  NSRect oldFrame;
  
  oldFrame = [self frame];
  [super setFrame:frame];
  if (oldFrame.size.width != frame.size.width) {
    [lineLocationCache removeAllObjects];
    [self updateViewHeight];
    [self setNeedsDisplay:YES];
  }
}


- (void)drawRect:(NSRect)dirtyRect {
  CGContextRef cgc = [[NSGraphicsContext currentContext] graphicsPort];
  const CGAffineTransform cga = {1.0, 0.0, 0.0, -1.0, 0.0, 0.0};
  NSRange line;
  NSPoint point;
  NSInteger i, c;
  NSString *tmp;
  
  CGContextSetTextDrawingMode(cgc, kCGTextFill);
  CGContextSetTextMatrix(cgc, cga);
  
  [[NSColor whiteColor] set];
  NSRectFill(dirtyRect);
  [[NSColor blackColor] set];
  
  i = [self lineIndexForPoint:dirtyRect.origin];
  c = [lineRanges count];
  point = [self locationForLine:i];
  while (point.y < NSMaxY(dirtyRect)) {
    line = [[lineRanges objectAtIndex:i] rangeValue];
    tmp = [storage substringWithRange:line];
    [self drawLine:tmp atPoint:point withCursor:(i == c-1)];
    i++;
    if (i < c)
      point = [self locationForLine:i];
    else
      break;
  }
  
  [super drawRect:dirtyRect];
}


- (void)cacheLocationsForLines:(NSRange)lr {
  NSValue *pointval;
  NSPoint point;
  
  if (lr.location) {
    pointval = [lineLocationCache objectForKey:@(lr.location-1)];
    NSAssert(pointval, @"cacheLocationsForLines: called with invalid range");
    point = [pointval pointValue];
    point.y += [self heightForLine:lr.location-1];
  } else {
    point = NSZeroPoint;
  }
  
  [lineLocationCache setObject:[NSValue valueWithPoint:point] forKey:@(lr.location)];
  lr.length--;
  lr.location++;
  
  for (; lr.length; lr.location++, lr.length--) {
    point.y += [self heightForLine:lr.location - 1];
    [lineLocationCache setObject:[NSValue valueWithPoint:point] forKey:@(lr.location)];
  }
}


- (NSPoint)locationForLine:(NSInteger)line {
  NSValue *pointval;
  NSInteger i;
  
  pointval = [lineLocationCache objectForKey:@(line)];
  if (pointval) return [pointval pointValue];
  
  for (i=line; i>=0; i--) {
    pointval = [lineLocationCache objectForKey:@(line)];
    if (pointval) break;
  }
  i++;
  [self cacheLocationsForLines:NSMakeRange(i, line + 1- i)];
  
  pointval = [lineLocationCache objectForKey:@(line)];
  NSAssert(pointval, @"cacheLocationsForLines: failed!");
  return [pointval pointValue];
}


- (CGFloat)heightForLine:(NSInteger)i {
  NSRange line;
  NSInteger hmul, lineWidth;
  
  lineWidth = [self bounds].size.width / charSize.width;
  line = [[lineRanges objectAtIndex:i] rangeValue];
  hmul = MAX(1, (((NSInteger)line.length - 1) / lineWidth) + 1);
  return hmul * charSize.height;
}


- (NSRect)rectForLine:(NSInteger)line {
  NSRect res;
  
  res.origin = [self locationForLine:line];
  res.size.height = [self heightForLine:line];
  res.size.width = [self bounds].size.width;
  return res;
}


- (NSPoint)drawLine:(NSString *)line atPoint:(NSPoint)point withCursor:(BOOL)cur {
  CTFontRef font = (__bridge CTFontRef)(dispFont);
  CGContextRef cgc = [[NSGraphicsContext currentContext] graphicsPort];
  UniChar *string;
  static CGGlyph *glyphs;
  static NSInteger glyphsBufSize = 0;
  CGPoint tmppos;
  NSInteger lineWidth, i, c, j;
  NSRect cursorRect;
  
  c = [line length];
  
  if (glyphsBufSize < c) {
    free(glyphs);
    glyphsBufSize = c * 2;
    glyphs = malloc(glyphsBufSize * sizeof(CGGlyph));
  }
  string = (UniChar*)[line cStringUsingEncoding:NSUTF16StringEncoding];
  CTFontGetGlyphsForCharacters(font, string, glyphs, c);

  CGContextSetTextPosition(cgc, point.x, point.y);
  cursorRect.origin = point;
  
  tmppos = NSMakePoint(0, 0);
  tmppos.y -= charSize.height - baselineOffset;
  lineWidth = j = [self bounds].size.width / charSize.width;
  for (i=0; i<c; i++) {
    if (j == lineWidth)
      point.y += charSize.height;
    
    CTFontDrawGlyphs(font, glyphs+i, &tmppos, 1, cgc);
    
    j--;
    if (j)
      tmppos.x += charSize.width;
    else {
      tmppos.x = point.x;
      tmppos.y -= charSize.height;
      j = lineWidth;
    }
  }
  
  if (cur) {
    cursorRect.origin.x += tmppos.x;
    cursorRect.origin.y -= tmppos.y + (charSize.height - baselineOffset);
    cursorRect.size = charSize;
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [[NSColor grayColor] set];
    NSRectFill(cursorRect);
    [[NSGraphicsContext currentContext] restoreGraphicsState];
  }
  
  return point;
}


@end
