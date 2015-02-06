//
//  AppDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import "MOSAppDelegate.h"
#import "MOSJobWindowController.h"
#import "MOSPreferencesWindowController.h"


@implementation MOSAppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self populateExamplesMenu];
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


- (IBAction)openPreferencesWindow:(id)sender {
  if (!prefsWc) {
    prefsWc = [[MOSPreferencesWindowController alloc] init];
  }
  [prefsWc showWindow:sender];
}


- (void)populateExamplesMenu {
  NSBundle *bundle;
  NSArray *examples;
  NSURL *example;
  NSString *exampleName;
  NSMenuItem *tempMenuItem;
  
  bundle = [NSBundle mainBundle];
  examples = [bundle URLsForResourcesWithExtension:@"s" subdirectory:@"Examples"];
  for (example in examples) {
    exampleName = [[example lastPathComponent] stringByDeletingPathExtension];
    
    tempMenuItem = [[NSMenuItem alloc] init];
    [tempMenuItem setTitle:exampleName];
    [tempMenuItem setTarget:self];
    [tempMenuItem setAction:@selector(openExample:)];
    [examplesMenu addItem:tempMenuItem];
  }
}


- (IBAction)openExample:(id)sender {
  NSBundle *bundle;
  NSString *exampleName;
  NSURL *example;
  NSDocumentController *sdc;
  NSError *err;
  
  exampleName = [sender title];
  bundle = [NSBundle mainBundle];
  example = [bundle URLForResource:exampleName withExtension:@"s"
    subdirectory:@"Examples"];
  if (!example) return;
  
  sdc = [NSDocumentController sharedDocumentController];
  if (![sdc duplicateDocumentWithContentsOfURL:example copying:NO
        displayName:exampleName error:&err])
    [NSApp presentError:err];
}


@end




