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


#pragma mark - Initialization


- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  [self awakeFromNib];
  return self;
}


- (void)awakeFromNib {
  viewPadding = NSMakeSize(3, 0);
  storage = [[NSMutableString alloc] init];
  lineBuffer = [[NSMutableString alloc] init];
  lineRanges = [[NSMutableArray alloc] init];
  [lineRanges addObject:[NSValue valueWithRange:NSMakeRange(0, 0)]];
  lineLocationCache = [[NSMutableDictionary alloc] init];
  
  dispFont = [NSFont userFixedPitchFontOfSize:11.0];
  [self reloadFontInfo];
}


#pragma mark - NSView overrides


- (void)resetCursorRects {
  [self addCursorRect:[self visibleRect] cursor:[NSCursor IBeamCursor]];
}


- (BOOL)acceptsFirstResponder {
  return YES;
}


#pragma mark - Appearance properties


- (NSFont *)font {
  return dispFont;
}


- (void)setFont:(NSFont *)font {
  dispFont = font;
  [self reloadFontInfo];
  [self setNeedsDisplay:YES];
}


- (void)reloadFontInfo {
  CTFontRef font = (__bridge CTFontRef)(dispFont);
  NSInteger i;
  CGFloat ascent, descent, leading, advance;
  UniChar test[4] = {' ', '0', '8', 'W'};
  CGGlyph glyphs[4];
  CGSize adv[4];
  
  CTFontGetGlyphsForCharacters(font, test, glyphs, 4);
  CTFontGetAdvancesForGlyphs(font, kCTFontOrientationHorizontal, glyphs, adv, 4);
  advance = adv[0].width;
  for (i=1; i<4; i++)
    if (adv[i].width > advance)
      advance = adv[i].width;
  charSize.width = advance;
  
  ascent = CTFontGetAscent(font);
  descent = CTFontGetDescent(font);
  leading = CTFontGetLeading(font);
  charSize.height = ceil(ascent + descent + leading);
  baselineOffset = descent;
  [lineLocationCache removeAllObjects];
  [self updateViewHeight];
}


#pragma mark - NSTextInputClient


- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange {
  if (replacementRange.length == 0 && replacementRange.location >= [storage length])
    [self insertText:aString];
}


- (void)doCommandBySelector:(SEL)aSelector  {
  if ([self respondsToSelector:aSelector])
    ((void (*)(id, SEL, id))objc_msgSend)(self, aSelector, nil);
}


- (void)setMarkedText:(id)aString selectedRange:(NSRange)selectedRange
  replacementRange:(NSRange)replacementRange  { }


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


- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
  NSInteger l0, i, w;
  NSPoint p0, p1;
  NSRect res, tr = [self textRect];
  NSRange r0;
  
  p0 = [self originOfCharacterAtIndex:aRange.location outputLine:&l0];
  p1 = [self originOfCharacterAtIndex:NSMaxRange(aRange) outputLine:NULL];
  
  res.origin = p0;
  res.size.height = charSize.height;
  if (p0.y != p1.y) {
    res.size.width = tr.size.width - res.origin.x;
    if (actualRange) {
      r0 = [[lineRanges objectAtIndex:l0] rangeValue];
      i = aRange.location - r0.location;
      w = tr.size.width / charSize.width;
      aRange.length = w - i % w;
      *actualRange = aRange;
    }
  } else {
    res.size.width = p1.x - p0.x;
    if (actualRange) *actualRange = aRange;
  }
  return res;
}


- (NSArray *)validAttributesForMarkedText {
  return @[];
}


- (BOOL)isFlipped {
  return YES;
}


#pragma mark - Hit Testing


/* Returns [storage length] if the cursor points outside the contents */
- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint  {
  NSInteger guess, startchar, c, lineWidth;
  NSRange lineRange;
  NSRect lineRect, tr = [self textRect];
  
  guess = [self lineIndexForPoint:aPoint];
  lineRect = [self rectForLine:guess];
  lineWidth = tr.size.width / charSize.width;
  
  aPoint.y = MAX(0, aPoint.y - lineRect.origin.y);
  aPoint.x = MIN(MAX(0, aPoint.x - lineRect.origin.x), tr.size.width);
  startchar = (NSInteger)(aPoint.y / charSize.height) * lineWidth;
  c = startchar + (NSInteger)(aPoint.x / charSize.width);
  
  lineRange = [[lineRanges objectAtIndex:guess] rangeValue];
  if (c >= lineRange.length) {
    if (lineRange.location + c >= [storage length])
      return [storage length];
    lineRange = [storage lineRangeForRange:lineRange];
    return MAX(0, (NSInteger)NSMaxRange(lineRange) - 1);
  }
  return lineRange.location + c;
}


- (NSInteger)lineIndexForPoint:(NSPoint)aPoint {
  NSInteger guess, lines, sb, se;
  NSRect lineRect, tr = [self textRect];
  
  lines = [lineRanges count];
  
  if (aPoint.y < tr.origin.y)
    return 0;
  else if (aPoint.y >= NSMaxY(tr))
    return lines-1;
  
  guess = MIN((aPoint.y - tr.origin.y) / charSize.height, lines - 1);
  sb = 0;
  se = lines;
  
  lineRect = [self rectForLine:guess];
  lineRect.size.width = [self frame].size.width;
  lineRect.origin.x = 0;
  
  while (aPoint.y < lineRect.origin.y || aPoint.y >= NSMaxY(lineRect)) {
    if (aPoint.y < lineRect.origin.y) {
      if (guess == 0) return 0;
      se = guess - 1;
      guess = MIN(guess + (guess - sb) / 2, se);
    } else {
      if (guess == lines - 1) return lines-1;
      sb = guess + 1;
      guess = MAX(sb, guess + (se - guess) / 2);
    }
    
    lineRect = [self rectForLine:guess];
    lineRect.size.width = [self frame].size.width;
    lineRect.origin.x = 0;
  }
  
  return guess;
}


#pragma mark - Menus


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  if ([menuItem action] == @selector(copy:))
    return selection.length > 0;
  return YES;
}


+ (NSMenu *)defaultMenu {
  static NSMenu *cache;
  NSMenuItem *tmp;
  
  if (cache)
    return cache;
  
  cache = [[NSMenu alloc] init];
  
  tmp = [[NSMenuItem alloc] init];
  [tmp setAction:@selector(copy:)];
  [tmp setTitle:NSLocalizedString(@"Copy", @"Copy (teletype view menu)")];
  [cache addItem:tmp];
  
  tmp = [[NSMenuItem alloc] init];
  [tmp setAction:@selector(paste:)];
  [tmp setTitle:NSLocalizedString(@"Paste", @"Paste (teletype view menu)")];
  [cache addItem:tmp];
  
  return cache;
}


#pragma mark - Responder Actions


- (void)copy:(id)sender {
  NSPasteboard *pb;
  NSString *tmp;
  
  tmp = [storage substringWithRange:selection];
  pb = [NSPasteboard generalPasteboard];
  [pb clearContents];
  [pb setString:tmp forType:NSPasteboardTypeString];
}


- (void)paste:(id)sender {
  NSPasteboard *pb;
  
  pb = [NSPasteboard generalPasteboard];
  [self insertText:[pb stringForType:NSPasteboardTypeString]];
}


- (void)mouseDown:(NSEvent *)theEvent {
  NSPoint localPoint, evloc;
  
  evloc = [theEvent locationInWindow];
  localPoint = [self convertPoint:evloc fromView:nil];
  dragPivot = [self characterIndexForPoint:localPoint];
  if (dragPivot == NSNotFound)
    dragPivot = [storage length];
  
  selection.location = dragPivot;
  selection.length = 0;
  [self setNeedsDisplay:YES];
}


- (void)mouseDragged:(NSEvent *)theEvent {
  NSPoint localPoint, evloc;
  NSInteger tochar;
  
  evloc = [theEvent locationInWindow];
  localPoint = [self convertPoint:evloc fromView:nil];
  tochar = [self characterIndexForPoint:localPoint];
  
  if (tochar <= dragPivot) {
    selection.location = tochar;
    selection.length = dragPivot - tochar;
  } else {
    selection.location = dragPivot;
    selection.length = tochar - dragPivot;
  }

  if (localPoint.y < [self visibleRect].origin.y + charSize.height)
    [self scrollLineUp:nil];
  else if (localPoint.y > NSMaxY([self visibleRect]) - charSize.height)
    [self scrollLineDown:nil];
  [self setNeedsDisplay:YES];
}


- (void)scrollLineUp:(id)sender {
  id clipview;
  NSRect cvb;
  
  clipview = [self superview];
  if (![clipview isKindOfClass:[NSClipView class]])
    return;

  cvb = [clipview bounds];
  cvb.origin.y = MAX(0, cvb.origin.y - charSize.height);
  [clipview scrollToPoint:cvb.origin];
}


- (void)scrollLineDown:(id)sender {
  id clipview;
  NSRect cvb;
  CGFloat maxy;
  
  clipview = [self superview];
  if (![clipview isKindOfClass:[NSClipView class]])
    return;
  
  cvb = [clipview bounds];
  maxy = [self bounds].size.height - cvb.size.height;
  cvb.origin.y = MIN(cvb.origin.y + charSize.height, maxy);
  [clipview scrollToPoint:cvb.origin];
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


#pragma mark - Text storage methods


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


- (NSInteger)lineOfCharacterAtIndex:(NSUInteger)i {
  NSUInteger l, cs, ce;
  NSValue *srv;
  
  if (i >= [storage length])
    return [lineRanges count] - 1;
  
  [storage getLineStart:&cs end:NULL contentsEnd:&ce forRange:NSMakeRange(i, 0)];
  srv = [NSValue valueWithRange:NSMakeRange(cs, ce-cs)];
  
  l = [lineRanges indexOfObject:srv inSortedRange:NSMakeRange(0, [lineRanges count])
    options:0 usingComparator:^NSComparisonResult(NSValue *obj1, NSValue *obj2) {
      NSRange r1, r2;
      
      r1 = [obj1 rangeValue];
      r2 = [obj2 rangeValue];
      if (r1.location < r2.location)
        return NSOrderedAscending;
      else if (r1.location == r2.location)
        return NSOrderedSame;
      return NSOrderedDescending;
    }];
  return l;
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


#pragma mark - View Height


- (void)updateViewHeight {
  NSUInteger i;
  CGFloat h;
  
  i = [lineRanges count] - 1;
  h = [self locationForLine:i].y + [self heightForLine:i] + viewPadding.height;
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


#pragma mark - Metrics computation


- (NSRect)textRect {
  NSRect bounds;
  
  bounds = [self bounds];
  bounds.origin.x += viewPadding.width;
  bounds.origin.y += viewPadding.height;
  bounds.size.width -= 2 * viewPadding.width;
  bounds.size.height -= 2 * viewPadding.height;
  return bounds;
}


- (NSPoint)originOfCharacterAtIndex:(NSUInteger)i outputLine:(NSInteger *)lo {
  NSInteger l, lineWidth, hmul, wmul;
  NSPoint linezero, chardelta;
  NSRange r;
  NSRect tr = [self textRect];
  
  l = [self lineOfCharacterAtIndex:i];
  if (l < 0)
    return NSZeroPoint;
  r = [[lineRanges objectAtIndex:l] rangeValue];
  if (lo) *lo = l;
  
  lineWidth = tr.size.width / charSize.width;
  i -= r.location;
  hmul = i / lineWidth;
  wmul = i % lineWidth;
  chardelta = NSMakePoint(wmul * charSize.width, hmul * charSize.height);
  linezero = [self locationForLine:l];
  return NSMakePoint(chardelta.x + linezero.x, chardelta.y + linezero.y);
}


- (void)cacheLocationsForLines:(NSRange)lr {
  NSValue *pointval;
  NSPoint point;
  NSRect tr = [self textRect];
  
  if (lr.location) {
    pointval = [lineLocationCache objectForKey:@(lr.location-1)];
    NSAssert(pointval, @"cacheLocationsForLines: called with invalid range");
    point = [pointval pointValue];
    point.y += [self heightForLine:lr.location-1];
  } else {
    point = tr.origin;
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
  [self cacheLocationsForLines:NSMakeRange(i, line + 1 - i)];
  
  pointval = [lineLocationCache objectForKey:@(line)];
  NSAssert(pointval, @"cacheLocationsForLines: failed!");
  return [pointval pointValue];
}


- (CGFloat)heightForLine:(NSInteger)i {
  NSRange line;
  NSInteger hmul, lineWidth;
  NSRect tr = [self textRect];
  
  lineWidth = tr.size.width / charSize.width;
  line = [[lineRanges objectAtIndex:i] rangeValue];
  hmul = MAX(1, (((NSInteger)line.length - 1) / lineWidth) + 1);
  return hmul * charSize.height;
}


- (NSRect)rectForLine:(NSInteger)line {
  NSRect res;
  
  res.origin = [self locationForLine:line];
  res.size.height = [self heightForLine:line];
  res.size.width = [self textRect].size.width;
  return res;
}


#pragma mark - Drawing


- (void)drawRect:(NSRect)dirtyRect {
  CGContextRef cgc = [[NSGraphicsContext currentContext] graphicsPort];
  const CGAffineTransform cga = {1.0, 0.0, 0.0, -1.0, 0.0, 0.0};
  NSRange line;
  NSPoint point;
  NSInteger i, c;
  
  CGContextSetTextDrawingMode(cgc, kCGTextFill);
  CGContextSetTextMatrix(cgc, cga);
  
  [[NSColor whiteColor] set];
  NSRectFill(dirtyRect);
  
  [self drawSelection];
  
  [[NSColor blackColor] set];
  
  i = [self lineIndexForPoint:dirtyRect.origin];
  c = [lineRanges count];
  point = [self locationForLine:i];
  while (point.y < NSMaxY(dirtyRect)) {
    line = [[lineRanges objectAtIndex:i] rangeValue];
    [self drawLine:line atPoint:point withCursor:(i == c-1)];
    i++;
    if (i < c)
      point = [self locationForLine:i];
    else
      break;
  }
}


- (void)drawSelection {
  NSRange range = selection;
  NSRange l0, l1;
  NSInteger li0, li1;
  NSPoint start, end;
  NSRect r, tr = [self textRect];
  BOOL sameline, nlextend0, nlextend1;
  
  [[NSColor selectedTextBackgroundColor] set];
  
  if (!range.length)
    return;
    
  start = [self originOfCharacterAtIndex:range.location outputLine:&li0];
  end = [self originOfCharacterAtIndex:NSMaxRange(range)-1 outputLine:&li1];
  l0 = [[lineRanges objectAtIndex:li0] rangeValue];
  l1 = [[lineRanges objectAtIndex:li1] rangeValue];
  
  sameline = start.y == end.y;
  nlextend0 = range.location > NSMaxRange(l0);
  nlextend1 = NSMaxRange(range) > NSMaxRange(l1);
  
  if (sameline) {
    if (!nlextend1)
      end.x += charSize.width;
    else
      end.x = NSMaxX(tr);
    end.y += charSize.height;
    r.origin = start;
    r.size = NSMakeSize(end.x - start.x, end.y - start.y);
    if ([self needsToDrawRect:r])
      NSRectFill(r);
  } else {
    r.origin = start;
    r.size = NSMakeSize(NSMaxX(tr) - start.x, charSize.height);
    if ([self needsToDrawRect:r])
      NSRectFill(r);
    
    r.origin = NSMakePoint(tr.origin.x, start.y + charSize.height);
    r.size = NSMakeSize(tr.size.width, end.y - r.origin.y);
    if ([self needsToDrawRect:r])
      NSRectFill(r);
    
    if (!nlextend1)
      end.x += charSize.width;
    else
      end.x = NSMaxX(tr);
    r.origin = NSMakePoint(tr.origin.x, end.y);
    r.size = NSMakeSize(end.x - tr.origin.x, charSize.height);
    if ([self needsToDrawRect:r])
      NSRectFill(r);
  }
}


- (void)drawLine:(NSRange)range atPoint:(NSPoint)point withCursor:(BOOL)cur {
  CTFontRef font = (__bridge CTFontRef)(dispFont);
  NSString *line;
  CGContextRef cgc = [[NSGraphicsContext currentContext] graphicsPort];
  UniChar *string;
  static CGGlyph *glyphs;
  static NSInteger glyphsBufSize = 0;
  CGPoint tmppos;
  NSInteger lineWidth, i, c, j;
  NSRect cursorRect, tr = [self textRect];
  
  c = range.length;
  
  if (glyphsBufSize < c) {
    free(glyphs);
    glyphsBufSize = c * 2;
    glyphs = malloc(glyphsBufSize * sizeof(CGGlyph));
  }
  line = [storage substringWithRange:range];
  string = (UniChar*)[line cStringUsingEncoding:NSUTF16StringEncoding];
  CTFontGetGlyphsForCharacters(font, string, glyphs, c);

  CGContextSetTextPosition(cgc, point.x, point.y);
  cursorRect.origin = point;
  
  tmppos = NSMakePoint(0, 0);
  tmppos.y -= charSize.height - baselineOffset;
  lineWidth = j = tr.size.width / charSize.width;
  for (i=0; i<c; i++) {
    
    CTFontDrawGlyphs(font, glyphs+i, &tmppos, 1, cgc);
    
    j--;
    if (j)
      tmppos.x += charSize.width;
    else {
      tmppos.x = 0;
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
}


@end
