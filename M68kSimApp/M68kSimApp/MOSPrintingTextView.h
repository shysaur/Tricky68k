//
//  MOSPrintingTextView.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 06/02/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MOSPrintingTextView : NSTextView {
  NSPrintInfo *printInfo;
}

- (void)setPrintInfo:(NSPrintInfo*)pi;
- (void)setTabWidth:(NSInteger)tabWidth;

@end
