//
//  MOSPrintingTextView.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 06/02/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>


extern NSString * const MOSPrintFont;


@interface MOSPrintingTextView : NSTextView {
  NSInteger _tabWidth;
}

- (void)setTabWidth:(NSInteger)tabWidth;

@end
