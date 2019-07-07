//
//  MOSPrintingTextView.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 06/02/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Fragaria/Fragaria.h>
#import "MOSPrintingTextView.h"


NSString * const MOSPrintFont = @"MOSFont";
NSString * const MOSPrintColorScheme = @"MOSPrintColorScheme";


@implementation MOSPrintingTextView


- (instancetype)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  [self setTabWidth:4];
  return self;
}


- (BOOL)knowsPageRange:(NSRangePointer)range
{
  NSSize pageSize;
  NSUInteger len;
  NSRange wrange;
  NSLayoutManager *lm;
  NSPrintInfo *printInfo;
  
  printInfo = [[NSPrintOperation currentOperation] printInfo];
  [self setFont:[printInfo.dictionary objectForKey:MOSPrintFont]];
  
  if (self.highlightingParser) {
    MGSColourScheme *scheme = [printInfo.dictionary objectForKey:MOSPrintColorScheme];
    MGSHighlightAttributedString(self.textStorage, self.highlightingParser, scheme);
    self.backgroundColor = scheme.backgroundColor;
  }
  
  pageSize = [printInfo paperSize];
  pageSize.width -= [printInfo rightMargin] + [printInfo leftMargin];
  pageSize.height -= [printInfo topMargin] + [printInfo bottomMargin];
  [self setFrame:NSMakeRect(0, 0, pageSize.width, pageSize.height)];
  
  /* Force re-layout of the view */
  len = self.textStorage.length;
  if (len > 0) {
    wrange = NSMakeRange(0, len);
    lm = [self layoutManager];
    [lm invalidateLayoutForCharacterRange:wrange actualCharacterRange:NULL];
    [lm ensureLayoutForCharacterRange:wrange];
  }

  return [super knowsPageRange:range];
}


- (void)setTabWidth:(NSInteger)tabWidth
{
  CGFloat sizeOfTab;
  NSMutableParagraphStyle *style;
  NSMutableDictionary *ta;
  NSArray *tabs;
  NSTextStorage *ts;
  NSRange wholeRange;
  
  _tabWidth = tabWidth;
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


- (void)setFont:(NSFont *)font
{
  [super setFont:font];
  [self setTabWidth:_tabWidth];
}


@end
