//
//  MOSColoredView.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 30/03/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>


@interface MOSColoredView : NSView {
  NSColor *bgcolor;
}

- (void)setBackgroundColor:(NSColor*)color;
- (NSColor*)backgroundColor;

@property (nonatomic) BOOL disableHitTesting;

@end
