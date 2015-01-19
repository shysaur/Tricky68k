//
//  MOSProgressIndicator.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 19/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSProgressIndicator.h"


static BOOL settingWindow = NO;


@interface NSProgressIndicator()

- (void)_setWindow:(NSWindow*)window;

@end


@implementation MOSProgressIndicator


/* Fixing a bug in AppKit. _setWindow should not draw anything, but in
 * NSProgressIndicator, to initialize its animating/not animating state, if
 * if will animate it calls startAnimation:, which calls displayIfNeeded, and
 * thus it draws.
 *
 * NSToolbar, being crappily designed, handles view items like image items,
 * using a specially subclassed NSImage which, at display time, replaces
 * itself with the custom view. The reason for this design decision is unknown
 * to me, and it is as bad as it sounds. But I guess we're stuck with it
 * because of backwards compatibility.
 *
 * When the custom view is a NSProgressIndicator which is set to start animating
 * immediately, when the NSProgressIndicator calls displayIfNeeded, the display 
 * code of the fake NSImage runs again (since the NSToolbarView has not
 * finished displaying yet, where the NSProgressIndicator is its area is still
 * invalid). Since the fake NSImage is not set up for handling this situation,
 * it happily instantiates our custom view again, creating an infinite
 * recursion.
 *
 * The fix is to hook NSProgressIndicator's displayIfNeeded to not run if it
 * was indirectly called by _setWindow. This makes it not draw anything when
 * it shouldn't, which was the root issue. */

- (void)_setWindow:(NSWindow*)window {
  settingWindow = YES;
  [super _setWindow:window];
  settingWindow = NO;
}


- (void)displayIfNeeded {
  if (settingWindow)
    return;
  [super displayIfNeeded];
}


@end
