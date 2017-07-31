//
//  MOSSimulatorToolbarDelegate.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/11/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorViewController;
@class MOSSourceDocument;
@class MOSExecutableDocument;


@interface MOSSimulatorToolbarDelegate : NSObject <NSToolbarDelegate> {
  IBOutlet MOSSimulatorViewController *simulatorVc;
  IBOutlet MOSSourceDocument *sourceDocument;
  IBOutlet MOSExecutableDocument *executableDocument;
}

@end
