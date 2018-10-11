//
//  MOSTeletypeView.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 02/06/15.
//  Copyright (c) 2015 danielecattaneo. All rights reserved.
//

#import "MOSTeletypeView.h"
#import <objc/objc-runtime.h>


static NSRange MOSMakeIndexRange(NSUInteger a, NSUInteger b) {
  if (a < b)
    return NSMakeRange(a, b - a);
  return NSMakeRange(b, a - b);
}


@implementation MOSTeletypeView {
  NSMutableString *storage;
  NSMutableString *lineBuffer;
  NSMutableArray *lineRanges; // <- no newlines!
  NSMutableDictionary *lineLocationCache;
  
  NSSize viewPadding;
  NSSize charSize;
  CGFloat baselineOffset;
  
  NSInteger dragPivot;
  NSRange selection;
  BOOL isActive;
  MOSSelectionGranularity selGranularity;
}


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
  
  _font = [NSFont userFixedPitchFontOfSize:11.0];
  _textColor = [NSColor textColor];
  _backgroundColor = [NSColor textBackgroundColor];
  _cursorColor = [NSColor systemGrayColor];
  [self reloadFontInfo];
}


#pragma mark - NSView overrides


- (void)resetCursorRects {
  [self addCursorRect:[self visibleRect] cursor:[NSCursor IBeamCursor]];
}


- (BOOL)acceptsFirstResponder {
  return YES;
}


- (BOOL)isOpaque {
  return YES;
}


#pragma mark - Appearance properties


- (void)setFont:(NSFont *)font {
  _font = font;
  [self reloadFontInfo];
  [self setNeedsDisplay:YES];
}


- (void)reloadFontInfo {
  CTFontRef font = (__bridge CTFontRef)([self font]);
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
  [self sizeToFit];
}


- (void)setTextColor:(NSColor *)textColor {
  _textColor = textColor;
  [self setNeedsDisplay:YES];
}


- (void)setBackgroundColor:(NSColor *)backgroundColor {
  _backgroundColor = backgroundColor;
  [self setNeedsDisplay:YES];
}


- (void)setCursorColor:(NSColor *)cursorColor {
  _cursorColor = cursorColor;
  [self setNeedsDisplay:YES];
}


#pragma mark - NSTextInputClient


- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{
  NSUInteger i;
  
  if (NSMaxRange(replacementRange) < [storage length])
    return;
  
  for (i=0; i<replacementRange.length; i++)
    [self deleteBackward:nil];
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
  return NSMakeRange(NSNotFound, 0);
}


- (BOOL)hasMarkedText  {
  return NO;
}


- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange
  actualRange:(NSRangePointer)actualRange  {
  NSRange allText;
  static NSRange adj;
  NSString *res;
  NSDictionary *attr;
  
  allText = NSMakeRange(0, [storage length]);
  
  adj = NSIntersectionRange(aRange, allText);
  if (actualRange)
    *actualRange = adj;
  
  res = [storage substringWithRange:adj];
  attr = @{NSFontAttributeName: [self font]};
  return [[NSAttributedString alloc] initWithString:res attributes:attr];
}


/* Returned rect is in SCREEN coordinates! */
- (NSRect)firstRectForCharacterRange:(NSRange)range actualRange:(NSRangePointer)actualRange {
  NSRect viewc, winc;
  
  viewc = [self firstViewRectForCharacterRange:range actualRange:actualRange];
  winc = [self convertRect:viewc toView:nil];
  return [[self window] convertRectToScreen:winc];
}


- (NSRect)firstViewRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
  NSInteger l0, i, w;
  unichar lastchar;
  CGFloat lastcharwidth;
  NSPoint p0, p1;
  NSRect res, tr = [self textRect];
  NSRange r0;
  
  p0 = [self originOfCharacterAtIndex:aRange.location outputLine:&l0];
  p1 = [self originOfCharacterAtIndex:NSMaxRange(aRange)-1 outputLine:NULL];
  
  res.origin = p0;
  res.size.height = charSize.height;
  if (p0.y != p1.y) {
    res.size.width = NSMaxX(tr) - res.origin.x;
    if (actualRange) {
      r0 = [storage lineRangeForRange:[[lineRanges objectAtIndex:l0] rangeValue]];
      i = aRange.location - r0.location;
      w = tr.size.width / charSize.width;
      aRange.length = w - i % w;
      if (NSMaxRange(aRange) > NSMaxRange(r0))
        aRange.length = NSMaxRange(r0) - aRange.location;
      *actualRange = aRange;
    }
  } else {
    lastchar = [storage characterAtIndex:NSMaxRange(aRange)-1];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastchar])
      lastcharwidth = NSMaxX(tr) - p1.x;
    else
      lastcharwidth = charSize.width;
    
    res.size.width = p1.x - p0.x + lastcharwidth;
    if (actualRange)
      *actualRange = aRange;
  }
  return res;
}


- (NSArray *)validAttributesForMarkedText {
  return @[];
}


- (BOOL)isFlipped {
  return YES;
}


- (NSUInteger)characterIndexForPoint:(NSPoint)point {
  NSRect tmp;
  
  tmp.origin = point;
  tmp.size = NSMakeSize(0, 0);
  tmp = [[self window] convertRectFromScreen:tmp];
  tmp.origin = [self convertPoint:tmp.origin fromView:nil];
  return [self characterIndexForViewPoint:tmp.origin];
}


#pragma mark - Hit Testing


/* Returns [storage length] if the cursor points outside the contents.
 * Otherwise, always returns a valid character index. */
- (NSUInteger)characterIndexForViewPoint:(NSPoint)aPoint  {
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


/* Always returns a valid line index. */
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
  NSPoint localPoint;
  NSUInteger clicks;
  MOSSelectionGranularity gran;
  BOOL merge;
  
  clicks = [theEvent clickCount];
  if (clicks <= 1)
    gran = MOSSelectionGranularityCharacter;
  else if (clicks == 2)
    gran = MOSSelectionGranularityWord;
  else
    gran = MOSSelectionGranularityLine;
  
  localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  merge = [theEvent modifierFlags] & NSShiftKeyMask;
  [self startNewSelectionFromPoint:localPoint withGranularity:gran
    mergeWithPrevious:merge];
}


- (void)mouseDragged:(NSEvent *)theEvent {
  NSPoint localPoint;
  
  localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  [self continueSelectionToPoint:localPoint];
}


- (void)mouseUp:(NSEvent *)event {
  [self endSelection];
}


- (void)rightMouseDown:(NSEvent *)event {
  NSPoint localPoint;
  NSInteger charUnder;
  
  localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
  charUnder = [self characterIndexForViewPoint:localPoint];
  if (!NSLocationInRange(charUnder, selection)) {
    [self startNewSelectionFromPoint:localPoint
      withGranularity:MOSSelectionGranularityWord mergeWithPrevious:NO];
    [self endSelection];
  }
  
  [super rightMouseDown:event];
}


- (void)scrollLineUp:(id)sender {
  id clipview;
  NSRect cvb;
  
  clipview = [self superview];
  if (![clipview isKindOfClass:[NSClipView class]])
    return;

  cvb = [clipview bounds];
  cvb.origin.y = MAX(0, cvb.origin.y - charSize.height);
  [self scrollToPoint:cvb.origin];
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
  [self scrollToPoint:cvb.origin];
}


- (void)scrollToEndOfDocument:(id)sender {
  id clipview;
  CGFloat top;
  
  clipview = [self superview];
  if (![clipview isKindOfClass:[NSClipView class]])
    return;
  
  if ([clipview bounds].size.height < [self bounds].size.height) {
    top = [self bounds].size.height - [clipview bounds].size.height;
    [self scrollToPoint:NSMakePoint(0, top)];
  }
}


- (void)scrollToPoint:(NSPoint)pt {
  id clipview, scrollview;
  
  clipview = [self superview];
  if ([clipview isKindOfClass:[NSClipView class]]) {
    [clipview scrollToPoint:pt];
    
    scrollview = [clipview superview];
    if ([scrollview isKindOfClass:[NSScrollView class]])
      [scrollview reflectScrolledClipView:clipview];
  }
}


- (void)insertOutputText:(NSString *)text {
  [self setNeedsDisplayOfLastLine];
  [storage appendString:text];
  [self cacheLineRanges];
  [self sizeToFit];
  [self scrollToEndOfDocument:nil];
  [self setNeedsDisplayOfLastLine];
}


- (void)deleteBackward:(id)sender {
  if (![lineBuffer length]) {
    NSBeep();
    return;
  }
  
  [self setNeedsDisplayOfSelection];
  selection.length = 0;
  dragPivot = NSNotFound;
  
  [self setNeedsDisplayOfLastLine];
  [storage deleteCharactersInRange:NSMakeRange([storage length]-1, 1)];
  [lineBuffer deleteCharactersInRange:NSMakeRange([lineBuffer length]-1, 1)];
  [self cacheLineRanges];
  [self sizeToFit];
  [self scrollToEndOfDocument:nil];
  [self setNeedsDisplayOfLastLine];
}


- (void)keyDown:(NSEvent *)theEvent {
  [self interpretKeyEvents:@[theEvent]];
}


- (void)insertNewline:(id)sender {
  [self insertCharacter:'\n'];
}


- (void)insertText:(id)aString {
  NSInteger i, c;
  
  if ([aString isKindOfClass:[NSAttributedString class]])
    aString = [aString string];
  
  c = [aString length];
  for (i=0; i<c; i++)
    [self insertCharacter:[aString characterAtIndex:i]];
}


- (void)insertCharacter:(unichar)a {
  NSString *tmp;
  
  selection.length = 0;
  dragPivot = NSNotFound;
  
  if ([[NSCharacterSet newlineCharacterSet] characterIsMember:a]) {
    [self insertOutputText:@"\n"];
    if ([self.delegate respondsToSelector:@selector(typedString:)]) {
      [lineBuffer appendString:@"\n"];
      [self.delegate typedString:[lineBuffer copy]];
    }
    [lineBuffer setString:@""];
  } else {
    tmp = [NSString stringWithCharacters:&a length:1];
    [self insertOutputText:tmp];
    [lineBuffer appendString:tmp];
  }
}


- (BOOL)becomeFirstResponder {
  isActive = YES;
  [self setNeedsDisplayOfLastLine];
  return YES;
}


- (BOOL)resignFirstResponder {
  isActive = NO;
  [self setNeedsDisplayOfLastLine];
  return YES;
}


#pragma mark - Selection by dragging


- (void)startNewSelectionFromPoint:(NSPoint)localPoint
    withGranularity:(MOSSelectionGranularity)g mergeWithPrevious:(BOOL)merge {
  NSUInteger charidx;
  NSRange extrarange;
  
  selGranularity = g;
  localPoint = [self adjustPointForSelection:localPoint pivot:YES];
  charidx = [self characterIndexForViewPoint:localPoint];
  
  [self setNeedsDisplayOfSelection];
  
  if (merge) {
    extrarange = MOSMakeIndexRange(dragPivot, charidx);
    selection = NSUnionRange(selection, extrarange);
    dragPivot = selection.location;
  } else {
    dragPivot = charidx;
    selection.location = dragPivot;
    selection.length = 0;
  }
  [self snapSelectionToGranularity];
  
  [self setNeedsDisplayOfSelection];
}


- (void)continueSelectionToPoint:(NSPoint)localPoint {
  NSInteger tochar;
  
  if (dragPivot == NSNotFound) return;
  
  [self setNeedsDisplayOfSelection];
  
  localPoint = [self adjustPointForSelection:localPoint pivot:NO];
  tochar = [self characterIndexForViewPoint:localPoint];
  
  selection = MOSMakeIndexRange(dragPivot, tochar);
  [self snapSelectionToGranularity];

  if (localPoint.y < [self visibleRect].origin.y + charSize.height)
    [self scrollLineUp:nil];
  else if (localPoint.y > NSMaxY([self visibleRect]) - charSize.height)
    [self scrollLineDown:nil];
  
  [self setNeedsDisplayOfSelection];
}


- (void)endSelection {
  dragPivot = NSNotFound;
}


- (NSPoint)adjustPointForSelection:(NSPoint)p pivot:(BOOL)pivot {
  NSInteger c;
  
  switch (selGranularity) {
    case MOSSelectionGranularityCharacter:
      p.x += charSize.width / 2.0;
      break;
      
    case MOSSelectionGranularityWord:
      break;
    
    case MOSSelectionGranularityLine:
      if (!pivot) {
        c = [self characterIndexForViewPoint:p];
        p.x = 0;
        if (c > dragPivot)
          p.y += charSize.height;
      }
  }
  return p;
}


- (void)snapSelectionToGranularity {
  NSInteger start, end;
  
  if (selGranularity == MOSSelectionGranularityCharacter)
    return;
  
  start = selection.location;
  end = NSMaxRange(selection);
  
  if (selGranularity == MOSSelectionGranularityWord) {
    start = [self moveIndex:start toWordBoundaryWithDirection:-1];
    end = [self moveIndex:end toWordBoundaryWithDirection:+1];
    selection = MOSMakeIndexRange(start, end);
    
  } else if (selGranularity == MOSSelectionGranularityLine) {
    selection = [storage lineRangeForRange:selection];
  }
}


- (NSInteger)moveIndex:(NSInteger)i toWordBoundaryWithDirection:(NSInteger)d {
  NSCharacterSet *charset;
  unichar initialc;
  NSInteger nextc;
  BOOL initial;
  
  if ([storage length] == 0)
    return i;
  if (i < 0 || i >= [storage length])
    return i;
  
  initialc = [storage characterAtIndex:i];
  if ([[NSCharacterSet newlineCharacterSet] characterIsMember:initialc])
    return i;
  
  charset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  initial = [charset characterIsMember:initialc];
  
  nextc = i + d;
  while (nextc >= 0 && nextc < [storage length] &&
    [charset characterIsMember:[storage characterAtIndex:nextc]] == initial) {
    i += d;
    nextc += d;
  }
  
  return d > 0 ? i+d : i;
}


#pragma mark - Text storage methods


- (NSString *)string {
  return [storage copy];
}


- (void)setString:(NSString *)string {
  storage = [string mutableCopy];
  [lineLocationCache removeAllObjects];
  [self cacheLineRanges];
  [self sizeToFit];
  [self setNeedsDisplay:YES];
}


/* Always returns a valid line index, even if the character index is out of
 * bounds */
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


- (void)sizeToFit {
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
    [self sizeToFit];
    [self setNeedsDisplay:YES];
  }
}


- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
  [super resizeWithOldSuperviewSize:oldSize];
  [self sizeToFit];
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


/* Always returns a valid point. */
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
  
  lineWidth = MAX(1, tr.size.width / charSize.width);
  line = [[lineRanges objectAtIndex:i] rangeValue];
  hmul = MAX(1, (((NSInteger)line.length - 1) / lineWidth) + 1);
  return hmul * charSize.height;
}


/* Line rects must have no gaps between them and must be coherent with
 * the values returned by -heightForLine: and -locationForLine:, otherwise
 * -lineIndexForPoint: will enter an infinite loop. */
- (NSRect)rectForLine:(NSInteger)line {
  NSRect res;
  
  res.origin = [self locationForLine:line];
  res.size.height = [self heightForLine:line];
  res.size.width = [self textRect].size.width;
  return res;
}


#pragma mark - Drawing


- (void)setNeedsDisplayOfSelection {
  NSRect t0, t1;
  
  if (!selection.length)
    return;
  
  t0 = [self rectForLine:[self lineOfCharacterAtIndex:selection.location]];
  t1 = [self rectForLine:[self lineOfCharacterAtIndex:NSMaxRange(selection)-1]];
  [self setNeedsDisplayInRect:NSUnionRect(t0, t1)];
}


- (void)setNeedsDisplayOfLastLine {
  [self setNeedsDisplayInRect:[self rectForLine:[lineRanges count]-1]];
}


- (void)drawRect:(NSRect)dirtyRect {
  CGContextRef cgc = [[NSGraphicsContext currentContext] graphicsPort];
  const CGAffineTransform cga = {1.0, 0.0, 0.0, -1.0, 0.0, 0.0};
  NSRange line;
  NSPoint point;
  NSInteger i, c;
  
  CGContextSetTextDrawingMode(cgc, kCGTextFill);
  CGContextSetTextMatrix(cgc, cga);
  
  [[self backgroundColor] set];
  NSRectFill(dirtyRect);
  
  i = [self lineIndexForPoint:dirtyRect.origin];
  c = [lineRanges count];
  point = [self locationForLine:i];
  while (point.y < NSMaxY(dirtyRect)) {
    line = [[lineRanges objectAtIndex:i] rangeValue];
    [self drawSelectionInRange:[storage lineRangeForRange:line]];
    [self drawTextInRange:line atPoint:point];
    i++;
    if (i < c)
      point = [self locationForLine:i];
    else
      break;
  }
  
  [self drawCursor];
}


- (void)drawSelectionInRange:(NSRange)range {
  NSRect selRect;
  NSRange actRange;
  
  range = NSIntersectionRange(range, selection);
  if (!range.length)
    return;
  
  while (range.length > 0) {
    selRect = [self firstViewRectForCharacterRange:range actualRange:&actRange];
    [[NSColor selectedTextBackgroundColor] set];
    NSRectFill(selRect);
    
    range.length = NSMaxRange(range) - NSMaxRange(actRange);
    range.location = NSMaxRange(actRange);
  }
}


- (void)drawCursor {
  NSRect cursor;
  NSBezierPath *bp;
  
  cursor.origin = [self originOfCharacterAtIndex:[storage length] outputLine:nil];
  cursor.size = charSize;
  if ([self needsToDrawRect:cursor]) {
    if (isActive) {
      [[self cursorColor] set];
      NSRectFillUsingOperation(cursor, NSCompositeSourceOver);
    } else {
      cursor.origin.x += .5;
      cursor.origin.y += .5;
      cursor.size.width -= 1;
      cursor.size.height -= 1;
      bp = [NSBezierPath bezierPathWithRect:cursor];
      [[self cursorColor] setStroke];
      [bp stroke];
    }
  }
}


- (void)drawTextInRange:(NSRange)range atPoint:(NSPoint)point {
  CTFontRef font = (__bridge CTFontRef)([self font]);
  CGContextRef cgc = [[NSGraphicsContext currentContext] graphicsPort];
  static UniChar *string = NULL;
  static CGGlyph *glyphs = NULL;
  static NSInteger bufsize = 0;
  CGPoint tmppos;
  NSInteger lineWidth, i, c, j;
  NSRect tr = [self textRect];
  
  [[self textColor] set];
  
  c = range.length;
  if (bufsize < c) {
    free(glyphs);
    free(string);
    bufsize = c * 2;
    glyphs = malloc(bufsize * sizeof(CGGlyph));
    string = malloc(bufsize * sizeof(UniChar));
  }
  [storage getCharacters:string range:range];
  
  CTFontGetGlyphsForCharacters(font, string, glyphs, c);
  CGContextSetTextPosition(cgc, point.x, point.y);
  
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
}


- (void)drawBackgroundOverhangInRect:(NSRect)rect {
  [[self backgroundColor] set];
  NSRectFill(rect);
}


@end
