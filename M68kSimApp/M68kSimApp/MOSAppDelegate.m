//
//  AppDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import "MOSAppDelegate.h"
#import "MOSJobWindowController.h"


@implementation MOSAppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}


- (IBAction)openJobsWindow:(id)sender {
  if (!jobsWc) {
    jobsWc = [[MOSJobWindowController alloc] initWithWindowNibName:@"MOSJobWindow"];
  }
  [jobsWc showWindow:sender];
}


@end
