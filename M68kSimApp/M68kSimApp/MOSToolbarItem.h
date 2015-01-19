//
//  MOSToolbarItem.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 19/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MOSToolbarItem : NSToolbarItem {
  NSSize viewSize;
}

- (void)setView:(NSView*)view;

@end
