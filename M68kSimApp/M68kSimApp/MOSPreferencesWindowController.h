//
//  MOSPreferencesWindowController.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 14/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>


@interface MOSPreferencesWindowController : NSWindowController {
  NSMutableArray *prefPanes;
  NSInteger currentPanel;
  IBOutlet NSToolbar *toolbar;
}

- (IBAction)clickedPreferenceTab:(id)sender;

@end
