//
//  MOSSourceBreakpointDelegate.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 04/03/16.
//  Copyright © 2016 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Fragaria/Fragaria.h>


@class MOSListingDictionary;
@class MOSSource;


@interface MOSSourceBreakpointDelegate : NSObject <MGSBreakpointDelegate> {
  NSMutableIndexSet *breakpointList;
  NSMutableDictionary *addressToOriginalLines;
  MGSFragariaView *fragaria;
  __weak MOSSource *source;
}

- (instancetype)initWithFragaria:(MGSFragariaView *)f source:(MOSSource *)s;

- (NSSet *)breakpointAddressesWithListingDictionary:(MOSListingDictionary *)ld;
- (void)syncBreakpointsWithAddresses:(NSSet *)as listingDictionary:(MOSListingDictionary *)ld;

- (NSSet *)breakpointsForFragaria:(MGSFragariaView *)sender;
- (void)toggleBreakpointForFragaria:(MGSFragariaView *)sender onLine:(NSUInteger)line;

@end
