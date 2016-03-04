//
//  MOS68kListingDictionary.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 04/03/16.
//  Copyright © 2016 Daniele Cattaneo. All rights reserved.
//

#import "MOSListingDictionary.h"


@interface MOS68kListingDictionary : MOSListingDictionary {
  NSDictionary *lineToAddress;
  NSDictionary *addressToLine;
  NSUInteger firstSeenLine;
  NSUInteger lastSeenLine;
}

@end
