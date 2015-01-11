//
//  MOSJobWindowController.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 11/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSJobWindowController.h"
#import "MOSJobStatusManager.h"


@implementation MOSJobWindowController


- (void)windowDidLoad {
  NSNotificationCenter *nc;
  
  nc = [NSNotificationCenter defaultCenter];
  
  [super windowDidLoad];
  if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
    [[self window] setTitleVisibility: NSWindowTitleHidden];
    [nc addObserver:self selector:@selector(windowDidBecomeMainWindow) name:NSWindowDidBecomeMainNotification object:[self window]];
    [nc addObserver:self selector:@selector(windowDidResignMainWindow) name:NSWindowDidResignMainNotification object:[self window]];
  } else {
    [fakeTitle removeFromSuperview];
  }
}


- (void)windowDidBecomeMainWindow {
  [fakeTitle setTextColor:[NSColor colorWithCalibratedWhite:0.7/3.0 alpha:1]];
}


- (void)windowDidResignMainWindow {
  [fakeTitle setTextColor:[NSColor colorWithCalibratedWhite:2.0/3.0 alpha:1]];
}


- (IBAction)clearJobList:(id)sender {
  [[MOSJobStatusManager sharedJobStatusManger] clearJobList];
}


- (void)dealloc {
  NSNotificationCenter *nc;
  
  nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
}


@end
