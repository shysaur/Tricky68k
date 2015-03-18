//
//  MOSExecutable.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MOSDocument.h"


@class MOSSimulatorViewController;
@class MOSSimulatorProxy;


@interface MOSExecutable : MOSDocument {
  NSWindowController *wc;
  NSWindow *window;
  MOSSimulatorProxy *simProxy;
  IBOutlet MOSSimulatorViewController *simVc;
}

@end
