//
//  MOSSimulatorTouchBarDelegate.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 06/04/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorViewController;


@interface MOSSimulatorTouchBarDelegate : NSObject <NSTouchBarDelegate>

@property (nonatomic) MOSSimulatorViewController *simulatorViewController;

- (NSTouchBar *)makeSourceDocumentTouchBar;
- (NSTouchBar *)makeExecutableDocumentTouchBar;

@end
