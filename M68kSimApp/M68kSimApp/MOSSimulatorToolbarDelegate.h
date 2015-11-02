//
//  MOSSimulatorToolbarDelegate.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/11/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorViewController;
@class MOSSource;


@interface MOSSimulatorToolbarDelegate : NSObject <NSToolbarDelegate> {
  IBOutlet MOSSimulatorViewController *simulatorVc;
  IBOutlet MOSSource *sourceDocument;
}

@end
