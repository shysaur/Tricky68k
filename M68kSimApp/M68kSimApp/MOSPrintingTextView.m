//
//  MOSPrintingTextView.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 06/02/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
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


@end
