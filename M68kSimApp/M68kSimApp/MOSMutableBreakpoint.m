//
//  MOSMutableBreakpoint.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 04/10/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSMutableBreakpoint.h"


@implementation MOSMutableBreakpoint


- (instancetype)initWithAddress:(uint32_t)a {
  return [self initWithAddress:a symbolTable:@{} symbolLocator:@[]];
}


- (instancetype)initWithAddress:(uint32_t)a symbolTable:(NSDictionary*)st
                  symbolLocator:(NSArray*)l {
  self = [super init];
  _address = a;
  _symbolLocator = l;
  _symbolTable = st;
  return self;
}


- (NSNumber *)address {
  return @(_address);
}


- (void)setAddress:(NSNumber *)a {
  _address = [a unsignedIntValue];
  
  [self willChangeValueForKey:@"symbolicLocation"];
  _locationCache = nil;
  [self didChangeValueForKey:@"symbolicLocation"];
}


- (uint32_t)rawAddress {
  return _address;
}


- (NSString *)symbolicLocation {
  NSInteger i;
  NSNumber *n, *a;
  NSString *sym;
  uint32_t off;
  
  if (_locationCache)
    return _locationCache;
  
  a = [self address];
  i = [_symbolLocator indexOfObject:a
      inSortedRange:NSMakeRange(0, [_symbolLocator count])
      options: NSBinarySearchingInsertionIndex | NSBinarySearchingLastEqual
      usingComparator:^ NSComparisonResult(id obj1, id obj2) {
    return [obj1 compare:obj2];
  }];
  
  if (i == 0) {
    sym = @"0";
    off = [a unsignedIntValue];
  } else {
    n = [_symbolLocator objectAtIndex:i];
    if ([n isEqual:a]) {
      off = 0;
    } else {
      n = [_symbolLocator objectAtIndex:i-1];
      off = [a unsignedIntValue] - [n unsignedIntValue];
    }
    sym = [_symbolTable objectForKey:n];
  }
  
  if (off == 0)
    return _locationCache = sym;
  return _locationCache = [NSString stringWithFormat:@"%@ + 0x%X", sym, off];
}


@end
