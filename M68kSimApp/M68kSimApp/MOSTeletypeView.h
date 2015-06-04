//
//  MOSTeletypeView.h
//  TeletypeViewTest
//
//  Created by Daniele Cattaneo on 02/06/15.
//  Copyright (c) 2015 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol MOSTeletypeViewDelegate <NSObject>

- (void)typedString:(NSString *)lineBuf;

@end


@interface MOSTeletypeView : NSView <NSTextInputClient> {
  NSMutableString *storage;
  NSMutableString *lineBuffer;
  NSMutableArray *lineRanges; // <- no newlines!
  NSMutableDictionary *lineLocationCache;
  
  NSFont *dispFont;
  NSSize charSize;
  CGFloat baselineOffset;
}

- (void)insertOutputText:(NSString *)text;

- (NSString *)string;
- (void)setString:(NSString *)string;

@property (weak) id <MOSTeletypeViewDelegate> delegate;

@end
