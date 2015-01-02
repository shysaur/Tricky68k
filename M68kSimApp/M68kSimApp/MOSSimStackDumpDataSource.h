//
//  MOSSimStackDumpDataSource.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 02/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorProxy;


@interface MOSSimStackDumpDataSource : NSObject <NSTableViewDataSource> {
  MOSSimulatorProxy *simProxy;
}

- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp;

@end
