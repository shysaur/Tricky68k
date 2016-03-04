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


@interface MOSSourceBreakpointDelegate : NSObject <MGSBreakpointDelegate> {
  NSMutableSet *breakpointList;
  NSMutableDictionary *addressToOriginalLine;
  MGSFragariaView *fragaria;
}

- (instancetype)initWithFragaria:(MGSFragariaView *)f;

- (NSSet *)breakpointAddressesWithListingDictionary:(MOSListingDictionary *)ld;
- (void)syncBreakpointsWithAddresses:(NSSet *)as listingDictionary:(MOSListingDictionary *)ld;

- (NSSet *)breakpointsForFragaria:(MGSFragariaView *)sender;
- (void)toggleBreakpointForFragaria:(MGSFragariaView *)sender onLine:(NSUInteger)line;

@end
