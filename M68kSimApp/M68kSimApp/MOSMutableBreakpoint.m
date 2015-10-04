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
  self = [super init];
  _address = a;
  return self;
}


- (NSNumber *)address {
  return @(_address);
}


- (void)setAddress:(NSNumber *)a {
  _address = [a unsignedIntValue];
}


- (uint32_t)rawAddress {
  return _address;
}


@end
