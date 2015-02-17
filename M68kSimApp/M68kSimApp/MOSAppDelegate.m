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
  NSURL *examplesDirPlist;
  NSDictionary *example;
  NSString *exampleName;
  NSMenuItem *tempMenuItem;
  NSInteger i;
  
  bundle = [NSBundle mainBundle];
  examplesDirPlist = [bundle URLForResource:@"ExamplesList" withExtension:@"plist"];
  examplesData = [NSArray arrayWithContentsOfURL:examplesDirPlist];
  
  i = 0;
  for (example in examplesData) {
    if ([[example objectForKey:@"kind"] isEqual:@"separator"]) {
      tempMenuItem = [NSMenuItem separatorItem];
    } else {
      tempMenuItem = [[NSMenuItem alloc] init];
      [tempMenuItem setTag:i];
      
      exampleName = [example objectForKey:@"localizedTitle"];
      [tempMenuItem setTitle:exampleName];
      
      if ([example objectForKey:@"fileName"]) {
        [tempMenuItem setTarget:self];
        [tempMenuItem setAction:@selector(openExample:)];
      } else {
        [tempMenuItem setEnabled:NO];
      }
    }
    [examplesMenu addItem:tempMenuItem];
    i++;
  }
}


- (IBAction)openExample:(id)sender {
  NSBundle *bundle;
  NSString *exampleName, *exampleTitle;
  NSURL *example;
  NSDocumentController *sdc;
  NSError *err;
  NSInteger i;
  
  i = [sender tag];
  bundle = [NSBundle mainBundle];
  exampleName = [[examplesData objectAtIndex:i] objectForKey:@"fileName"];
  exampleName = [exampleName stringByDeletingPathExtension];
  example = [bundle URLForResource:exampleName withExtension:@"s"];
  if (!example) return;
  
  exampleTitle = [[examplesData objectAtIndex:i] objectForKey:@"localizedTitle"];
  sdc = [NSDocumentController sharedDocumentController];
  if (![sdc duplicateDocumentWithContentsOfURL:example copying:YES
        displayName:exampleTitle error:&err])
    [NSApp presentError:err];
}


@end




