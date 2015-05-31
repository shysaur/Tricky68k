//
//  MOSPrintingTextView.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 06/02/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSPrintingTextView.h"


@implementation MOSPrintingTextView


- (void)setPrintInfo:(NSPrintInfo*)pi {
  printInfo = pi;
}


- (BOOL)knowsPageRange:(NSRangePointer)range {
  NSSize pageSize;
  
  pageSize = [printInfo paperSize];
  pageSize.width -= [printInfo rightMargin] + [printInfo leftMargin];
  pageSize.height -= [printInfo topMargin] + [printInfo bottomMargin];
  [self setFrame:NSMakeRect(0, 0, pageSize.width, pageSize.height)];
  
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
