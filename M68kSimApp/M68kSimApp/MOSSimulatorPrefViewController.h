//
//  MOSSimulatorPrefViewController.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 17/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MOSSimulatorPrefViewController : NSViewController {
  IBOutlet NSTextField *fontPreviewView;
}

- (IBAction)changeDebuggerFont:(id)sender;

@end
