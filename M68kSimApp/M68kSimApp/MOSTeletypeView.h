//
//  MOSTeletypeView.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MOSTeletypeView : NSTextView {
  NSRect curRect;
  NSInteger lastCur;
}

- (void)setTeletypeCursorPosition:(NSInteger)cur;

@end
