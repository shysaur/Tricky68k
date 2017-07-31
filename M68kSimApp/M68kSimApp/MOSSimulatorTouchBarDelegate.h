//
//  MOSSimulatorTouchBarDelegate.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 06/04/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorViewController;
@class MOSSourceDocument;


@interface MOSSimulatorTouchBarDelegate : NSObject <NSTouchBarDelegate>

@property (nonatomic, weak) MOSSimulatorViewController *simulatorViewController;
@property (nonatomic, weak) MOSSourceDocument *sourceDocument;

- (NSTouchBar *)makeSourceDocumentTouchBar;
- (NSTouchBar *)makeExecutableDocumentTouchBar;

@end
