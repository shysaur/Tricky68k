//
//  AppDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import "MOSAppDelegate.h"
#import "MOSJobWindowController.h"
#import "MOSPreferencesWindowController.h"
#import "MOSPlatformManager.h"
#import "MOSPlatform.h"


@implementation MOSAppDelegate


- (void)applicationWillFinishLaunching:(NSNotification *)notification {
  NSError *err;
  
  if (![[MOSPlatformManager sharedManager] loadPlatformsWithError:&err]) {
    [NSApp presentError:err];
    [NSApp terminate:nil];
  }
}


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
  NSDictionary *example;
  NSString *exampleName;
  NSMenuItem *tempMenuItem;
  NSInteger i;
  
  examplesData = [[[MOSPlatformManager sharedManager] defaultPlatform] examplesList];
  
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
  NSString *exampleName, *exampleTitle;
  NSURL *example;
  NSDocumentController *sdc;
  NSError *err;
  MOSPlatform *platf;
  NSInteger i;
  
  i = [sender tag];
  platf = [[MOSPlatformManager sharedManager] defaultPlatform];
  exampleName = [[examplesData objectAtIndex:i] objectForKey:@"fileName"];
  example = [platf URLForExampleFile:exampleName];
  if (!example) {
    NSLog(@"Couldn't find the example file %@", exampleName);
    return;
  }
  
  exampleTitle = [[examplesData objectAtIndex:i] objectForKey:@"localizedTitle"];
  sdc = [NSDocumentController sharedDocumentController];
  if (![sdc duplicateDocumentWithContentsOfURL:example copying:YES
        displayName:exampleTitle error:&err])
    [NSApp presentError:err];
}


@end




