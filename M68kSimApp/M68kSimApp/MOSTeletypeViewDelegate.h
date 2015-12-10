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


@class MOSSimulator;


@interface MOSTeletypeViewDelegate : MOSSimulatorSubviewDelegate <MOSTeletypeViewDelegate> {
  MOSSimulator *simProxy;
  IBOutlet MOSTeletypeView *textView;
}

- (void)setSimulatorProxy:(MOSSimulator*)sp;

- (void)typedString:(NSString*)str;

@end
