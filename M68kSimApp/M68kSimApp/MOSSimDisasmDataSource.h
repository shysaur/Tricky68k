//
//  MOSSimDisasmDataSource.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 01/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>
#import "MOSSimTableViewDelegate.h"


@interface MOSSimDisasmDataSource : MOSSimTableViewDelegate <NSTableViewDataSource, NSTableViewDelegate> {
  NSInteger maxLines, cacheStart;
  uint32_t addrCacheStart, addrCacheEnd, centerAddr;
  NSSet *breakpoints;
  NSMutableArray *lineCache;
}

- (NSInteger)programCounterRow;
- (IBAction)clickedTableView:(id)sender;

@end
