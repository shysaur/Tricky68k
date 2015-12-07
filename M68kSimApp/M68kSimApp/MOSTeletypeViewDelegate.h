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


@class MOS68kSimulator;


@interface MOSTeletypeViewDelegate : MOSSimulatorSubviewDelegate <MOSTeletypeViewDelegate> {
  MOS68kSimulator *simProxy;
  IBOutlet MOSTeletypeView *textView;
}

- (void)setSimulatorProxy:(MOS68kSimulator*)sp;

- (void)typedString:(NSString*)str;

@end
