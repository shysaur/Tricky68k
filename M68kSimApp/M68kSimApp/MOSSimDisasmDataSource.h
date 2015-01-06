//
//  MOSSimDisasmDataSource.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 01/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MOSSimTableViewDelegate.h"


@class MOSSimulatorProxy;


@interface MOSSimDisasmDataSource : MOSSimTableViewDelegate <NSTableViewDataSource> {
  NSInteger maxLines, cacheStart;
  uint32_t addrCacheStart, addrCacheEnd, centerAddr;
  NSMutableArray *lineCache;
}

- (NSInteger)programCounterRow;

@end
