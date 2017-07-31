//
//  MOSSourceBreakpointDelegate.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 04/03/16.
//  Copyright © 2016 Daniele Cattaneo. All rights reserved.
//

#import "MOSSourceBreakpointDelegate.h"
#import "MOSListingDictionary.h"
#import "MOSSourceDocument.h"


@implementation MOSSourceBreakpointDelegate


- (instancetype)initWithFragaria:(MGSFragariaView *)f source:(MOSSourceDocument *)s {
  self = [super init];
  fragaria = f;
  source = s;
  breakpointList = [[NSMutableIndexSet alloc] init];
  [fragaria setBreakpointDelegate:self];
  return self;
}


- (NSSet *)breakpointAddressesWithListingDictionary:(MOSListingDictionary *)ld {
  NSMutableSet *res;
  
  res = [NSMutableSet set];
  addressToOriginalLines = [NSMutableDictionary dictionary];
  
  [breakpointList enumerateIndexesUsingBlock:^(NSUInteger l, BOOL *stop) {
    NSNumber *a;
    NSMutableIndexSet *tmp;
    
    a = [ld addressForSourceLine:l];
    if (!a)
      NSLog(@"Address for line %ld not found.", l);
    else {
      [res addObject:a];
      tmp = [addressToOriginalLines objectForKey:a];
      if (!tmp) {
        tmp = [NSMutableIndexSet indexSetWithIndex:l];
        [addressToOriginalLines setObject:tmp forKey:a];
      } else
        [tmp addIndex:l];
    }
  }];
  
  return [res copy];
}


- (void)syncBreakpointsWithAddresses:(NSSet *)as listingDictionary:(MOSListingDictionary *)ld {
  NSNumber *this;
  NSIndexSet *lines;
  NSUInteger l;
  
  [breakpointList removeAllIndexes];
  for (this in as) {
    lines = [addressToOriginalLines objectForKey:this];
    if (!lines) {
      l = [ld sourceLineForAddress:this];
      if (l == NSNotFound) {
        NSLog(@"Line for address %@ not found.", this);
        continue;
      }
      lines = [NSIndexSet indexSetWithIndex:l];
    }
    [breakpointList addIndexes:lines];
  }
  [fragaria reloadBreakpointData];
}


- (NSIndexSet *)breakpointsForFragaria:(MGSFragariaView *)sender {
  return [breakpointList copy];
}


- (NSColor *)breakpointColourForLine:(NSUInteger)line ofFragaria:(MGSFragariaView *)sender {
  static NSColor *cache;
  
  if (!cache)
    cache = [NSColor colorWithCalibratedRed:0.043 green:0.227 blue:0.996 alpha:1.0];
  return cache;
}


- (void)toggleBreakpointForFragaria:(MGSFragariaView *)sender onLine:(NSUInteger)line {
  if ([breakpointList containsIndex:line])
    [breakpointList removeIndex:line];
  else
    [breakpointList addIndex:line];
  [source breakpointsShouldSyncToSimulator:self];
}


- (void)fixBreakpointsOfAddedLines:(NSInteger)delta inLineRange:(NSRange)newRange ofFragaria:(MGSFragariaView *)sender
{
  NSRange oldRange;
  BOOL changed = NO;
  NSUInteger tmp, minAffectedIdx;
  
  oldRange = newRange;
  oldRange.length -= delta;
  
  if (delta < 0) {
    tmp = [breakpointList indexLessThanIndex:NSMaxRange(oldRange)];
    if (tmp != NSNotFound && tmp >= NSMaxRange(newRange)) {
      /* Move all breakpoints that were located in deleted lines to the
       * end of the new range. */
      [breakpointList addIndex:NSMaxRange(newRange)-1];
      changed = YES;
    }
    minAffectedIdx = NSMaxRange(newRange);
  } else {
    minAffectedIdx = NSMaxRange(oldRange);
  }
  
  if ([breakpointList indexGreaterThanOrEqualToIndex:minAffectedIdx] != NSNotFound) {
    [breakpointList shiftIndexesStartingAtIndex:NSMaxRange(oldRange) by:delta];
    changed = YES;
  }
  if (changed) {
    [fragaria reloadBreakpointData];
    [source breakpointsShouldSyncToSimulator:self];
  }
}


@end
