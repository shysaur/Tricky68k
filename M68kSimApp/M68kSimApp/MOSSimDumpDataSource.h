//
//  MOSSimDumpDataSource.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 31/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorProxy;


@interface MOSSimDumpDataSource : NSObject <NSTableViewDataSource> {
  int64_t cachedBase;
  NSArray *cache;
  MOSSimulatorProxy *simProxy;
}

- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp;
- (void)invalidateCache;

@end
