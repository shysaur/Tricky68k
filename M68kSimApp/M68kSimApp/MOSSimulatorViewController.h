//
//  MOSSimulatorViewController.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorProxy;

@interface MOSSimulatorViewController : NSViewController {
  MOSSimulatorProxy *simProxy;
}

- (void)setSimulatedExecutable:(NSURL*)url;

@end
