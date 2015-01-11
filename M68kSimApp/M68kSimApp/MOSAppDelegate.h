//
//  AppDelegate.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MOSAppDelegate : NSObject <NSApplicationDelegate> {
  NSWindowController *jobsWc;
}

- (IBAction)openJobsWindow:(id)sender;

@end

