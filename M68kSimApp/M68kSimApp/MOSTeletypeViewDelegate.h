//
//  MOSTeletypeViewDelegate.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>
#import "MOSTeletypeView.h"
#import "MOSSimulatorSubviewDelegate.h"


@class MOSSimulatorProxy;


@interface MOSTeletypeViewDelegate : MOSSimulatorSubviewDelegate <MOSTeletypeViewDelegate> {
  MOSSimulatorProxy *simProxy;
  NSFileHandle *toSim;
  NSFileHandle *fromSim;
  IBOutlet MOSTeletypeView *textView;
}

- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp;

- (void)typedString:(NSString*)str;

@end
