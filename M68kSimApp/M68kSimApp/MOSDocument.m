//
//  MOSDocument.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 18/03/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSDocument.h"


@implementation MOSDocument


- (instancetype)init {
  self = [super init];
  transient = NO;
  return self;
}


- (BOOL)isTransient {
  return transient;
}


- (void)setTransient:(BOOL)t {
  transient = t;
}


- (void)updateChangeCount:(NSDocumentChangeType)change {
  [self setTransient:NO];
  [super updateChangeCount:change];
}


@end
