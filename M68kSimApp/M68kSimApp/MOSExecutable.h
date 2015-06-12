//
//  MOSExecutable.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>
#import "MOSDocument.h"


@class MOSSimulatorViewController;
@class MOSSimulator;


@interface MOSExecutable : MOSDocument {
  NSWindowController *wc;
  NSWindow *window;
  MOSSimulator *simProxy;
  IBOutlet MOSSimulatorViewController *simVc;
}

@end
