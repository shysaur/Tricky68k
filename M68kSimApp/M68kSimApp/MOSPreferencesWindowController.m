//
//  MOSPreferencesWindowController.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 14/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSPreferencesWindowController.h"
#import <MGSFragaria/MGSFragariaFontsAndColoursPrefsViewController.h>
#import <MGSFragaria/MGSFragariaTextEditingPrefsViewController.h>


@implementation MOSPreferencesWindowController


- (id)init {
  self = [super initWithWindowNibName:@"MOSPreferencesWindow"];
  currentPanel = -1;
  [self loadPrefPanes];
  return self;
}


- (void)windowDidLoad {
  [self switchTabToIndex:0 animate:NO keepXCenter:YES];
}


- (IBAction)clickedPreferenceTab:(id)sender {
  NSInteger paneIdx;
  const char *ident;
  
  ident = [[sender itemIdentifier] UTF8String];
  sscanf(ident, "%ld", &paneIdx);
  [self switchTabToIndex:paneIdx animate:YES keepXCenter:NO];
}


- (void)switchTabToIndex:(NSInteger)paneIdx animate:(BOOL)anim keepXCenter:(BOOL)kxc {
  NSWindow *wnd;
  NSRect rect, oldRect;
  NSViewController *pane;
  NSView *paneView;
  NSView *tempView;
  
  pane = [prefPanes objectAtIndex:paneIdx];
  paneView = [pane view];
  wnd = [self window];
  oldRect = [wnd frame];
  rect = [wnd frameRectForContentRect:[paneView frame]];
  if (!kxc)
    rect.origin.x = oldRect.origin.x;
  else
    rect.origin.x = oldRect.origin.x - (rect.size.width - oldRect.size.width) / 2;
  rect.origin.y = oldRect.origin.y - (rect.size.height - oldRect.size.height);
  
  if (anim) {
    tempView = [[NSView alloc] init];
    [wnd setContentView:tempView];
    [wnd setFrame:rect display:YES animate:YES]; /* blocking! */
  } else
    [wnd setFrame:rect display:YES];
  
  [wnd setContentView:paneView];
  [toolbar setSelectedItemIdentifier:[NSString stringWithFormat:@"%ld", paneIdx]];
  currentPanel = paneIdx;
}


- (void)loadPrefPanes
{
  prefPanes = [[NSMutableArray alloc] init];
  
  [prefPanes addObject:[[MGSFragariaTextEditingPrefsViewController alloc] init]];
  [prefPanes addObject:[[MGSFragariaFontsAndColoursPrefsViewController alloc] init]];
}


@end
