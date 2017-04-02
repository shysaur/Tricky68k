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


typedef NS_ENUM(NSInteger, MOSSelectionGranularity) {
  MOSSelectionGranularityCharacter = 1,
  MOSSelectionGranularityWord,
  MOSSelectionGranularityLine
};

@interface MOSTeletypeView : NSView <NSTextInputClient>

- (void)insertOutputText:(NSString *)text;

- (void)copy:(id)sender;
- (void)paste:(id)sender;

@property (nonatomic) NSString *string;
@property (nonatomic) NSFont *font;
@property (nonatomic) NSColor *textColor;
@property (nonatomic) NSColor *backgroundColor;
@property (nonatomic) NSColor *cursorColor;

@property (weak) IBOutlet id <MOSTeletypeViewDelegate> delegate;

@end
