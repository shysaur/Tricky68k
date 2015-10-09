//
//  MOSPrintingTextView.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 06/02/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSPrintingTextView.h"


@implementation MOSPrintingTextView


- (BOOL)knowsPageRange:(NSRangePointer)range {
  NSSize pageSize;
  NSRange crange, grange, wrange;
  NSLayoutManager *lm;
  NSPrintInfo *printInfo;
  
  printInfo = [[NSPrintOperation currentOperation] printInfo];
  
  pageSize = [printInfo paperSize];
  pageSize.width -= [printInfo rightMargin] + [printInfo leftMargin];
  pageSize.height -= [printInfo topMargin] + [printInfo bottomMargin];
  [self setFrame:NSMakeRect(0, 0, pageSize.width, pageSize.height)];
  
  /* Force re-layout of the view */
  if ([[self textStorage] length] > 0) {
    crange = NSMakeRange([[self textStorage] length]-1, 1);
    wrange = NSMakeRange(0, [[self textStorage] length]);
    lm = [self layoutManager];
    [lm invalidateLayoutForCharacterRange:wrange actualCharacterRange:NULL];
    grange = [lm glyphRangeForCharacterRange:crange actualCharacterRange:NULL];
    if (grange.location) {
      (void)[lm textContainerForGlyphAtIndex:grange.location-1 effectiveRange:NULL];
    }
  }

  return [super knowsPageRange:range];
}


- (void)setTabWidth:(NSInteger)tabWidth {
  CGFloat sizeOfTab;
  NSMutableParagraphStyle *style;
  NSMutableDictionary *ta;
  NSArray *tabs;
  NSTextStorage *ts;
  NSRange wholeRange;
  
  ta = [[self typingAttributes] mutableCopy];
  style = [[ta objectForKey:NSParagraphStyleAttributeName] mutableCopy];
  if (!style)
    style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  
  tabs = [style tabStops];
  for (id item in tabs) {
    [style removeTabStop:item];
  }
  
  sizeOfTab = [@" " sizeWithAttributes:ta].width * tabWidth;
  [style setDefaultTabInterval:sizeOfTab];
  
  [ta setObject:style forKey:NSParagraphStyleAttributeName];
  
  ts = [self textStorage];
  wholeRange = NSMakeRange(0, [[self string] length]);
  [self setTypingAttributes:ta];
  [ts addAttribute:NSParagraphStyleAttributeName value:style range:wholeRange];
}


@end
