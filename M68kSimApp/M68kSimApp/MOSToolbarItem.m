//
//  MOSToolbarItem.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 19/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSToolbarItem.h"


@implementation MOSToolbarItem


- (void)setView:(NSView*)view {
  NSRect viewRect;
  
  viewRect = [view frame];
  viewSize = viewRect.size;
  [super setView:view];
  [self setMaxSize:viewSize];
  [self setMinSize:viewSize];
}


- (NSSize)minSize {
  [self setMinSize:viewSize];
  return viewSize;
}


- (NSSize)maxSize {
  [self setMaxSize:viewSize];
  return viewSize;
}


@end
