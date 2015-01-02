//
//  MOSSimDisasmDataSource.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 01/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorProxy;


@interface MOSSimDisasmDataSource : NSObject <NSTableViewDataSource> {
  NSInteger maxLines, cacheStart;
  uint32_t addrCacheStart, addrCacheEnd, centerAddr;
  NSMutableArray *lineCache;
  MOSSimulatorProxy *simProxy;
}

- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp;
- (NSInteger)programCounterRow;

@end
