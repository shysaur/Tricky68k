//
//  MOSSimRegistersDataSource.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 01/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorProxy;


@interface MOSSimRegistersDataSource : NSObject <NSTableViewDataSource> {
  NSArray *rows;
  MOSSimulatorProxy *simProxy;
}

- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp;

@end
