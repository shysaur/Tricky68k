//
//  MOSExecutable.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorViewController;
@class MOSSimulatorProxy;


@interface MOSExecutable : NSDocument {
  NSWindowController *wc;
  NSWindow *window;
  MOSSimulatorProxy *simProxy;
  IBOutlet MOSSimulatorViewController *simVc;
}

@end
