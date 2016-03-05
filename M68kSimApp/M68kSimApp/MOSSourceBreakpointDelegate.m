//
//  MOSSourceBreakpointDelegate.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 04/03/16.
//  Copyright © 2016 Daniele Cattaneo. All rights reserved.
//

#import "MOSSourceBreakpointDelegate.h"
#import "MOSListingDictionary.h"
#import "MOSSource.h"


@implementation MOSSourceBreakpointDelegate


- (instancetype)initWithFragaria:(MGSFragariaView *)f source:(MOSSource *)s {
  self = [super init];
  fragaria = f;
  source = s;
  [fragaria setBreakpointDelegate:self];
  breakpointList = [[NSMutableSet alloc] init];
  return self;
}


- (NSSet *)breakpointAddressesWithListingDictionary:(MOSListingDictionary *)ld {
  NSMutableSet *res, *tmp;
  NSNumber *this, *a;
  
  res = [NSMutableSet set];
  addressToOriginalLines = [NSMutableDictionary dictionary];
  for (this in breakpointList) {
    a = [ld addressForSourceLine:[this integerValue]];
    if (!a)
      NSLog(@"Address for line %@ not found.", this);
    else {
      [res addObject:a];
      tmp = [addressToOriginalLines objectForKey:a];
      if (!tmp) {
        tmp = [NSMutableSet setWithObject:this];
        [addressToOriginalLines setObject:tmp forKey:a];
      } else
        [tmp addObject:this];
    }
  }
  
  return [res copy];
}


- (void)syncBreakpointsWithAddresses:(NSSet *)as listingDictionary:(MOSListingDictionary *)ld {
  NSNumber *this;
  NSSet *lines;
  NSUInteger l;
  
  [breakpointList removeAllObjects];
  for (this in as) {
    lines = [addressToOriginalLines objectForKey:this];
    if (!lines) {
      l = [ld sourceLineForAddress:this];
      if (l == NSNotFound) {
        NSLog(@"Line for address %@ not found.", this);
        continue;
      }
      lines = [NSSet setWithObject:@(l)];
    }
    [breakpointList unionSet:lines];
  }
  [fragaria reloadBreakpointData];
}


- (NSSet *)breakpointsForFragaria:(MGSFragariaView *)sender {
  return [breakpointList copy];
}


- (NSColor *)breakpointColourForLine:(NSUInteger)line ofFragaria:(MGSFragariaView *)sender {
  static NSColor *cache;
  
  if (!cache)
    cache = [NSColor colorWithCalibratedRed:0.043 green:0.227 blue:0.996 alpha:1.0];
  return cache;
}


- (void)toggleBreakpointForFragaria:(MGSFragariaView *)sender onLine:(NSUInteger)line {
  if ([breakpointList containsObject:@(line)])
    [breakpointList removeObject:@(line)];
  else
    [breakpointList addObject:@(line)];
  [source breakpointsShouldSyncToSimulator:self];
}


@end
