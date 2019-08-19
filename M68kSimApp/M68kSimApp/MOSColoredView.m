//
//  MOSColoredView.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 30/03/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSColoredView.h"


@implementation MOSColoredView


- (void)setBackgroundColor:(NSColor*)color {
  bgcolor = color;
}


- (NSColor*)backgroundColor {
  return bgcolor;
}


- (BOOL)isOpaque {
  return NO;
}


- (void)drawRect:(NSRect)dirtyRect {
  [NSGraphicsContext saveGraphicsState];
  [bgcolor set];
  NSRectFill(dirtyRect);
  [NSGraphicsContext restoreGraphicsState];
  
  [super drawRect:dirtyRect];
}


- (NSView *)hitTest:(NSPoint)point
{
  if (self.disableHitTesting)
    return self;
  return [super hitTest:point];
}


@end
