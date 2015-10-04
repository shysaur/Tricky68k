//
//  MOSMutableBreakpoint.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 04/10/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MOSMutableBreakpoint : NSObject {
  uint32_t _address;
}

- (instancetype)initWithAddress:(uint32_t)a;

- (NSNumber *)address;
- (void)setAddress:(NSNumber *)a;
- (uint32_t)rawAddress;

@end
