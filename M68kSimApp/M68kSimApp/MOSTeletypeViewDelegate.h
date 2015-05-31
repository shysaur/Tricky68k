//
//  MOSTeletypeViewDelegate.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>
#import "MOSSimulatorSubviewDelegate.h"


@class MOSSimulatorProxy;
@class MOSTeletypeView;


@interface MOSTeletypeViewDelegate : MOSSimulatorSubviewDelegate <NSTextViewDelegate> {
  MOSSimulatorProxy *simProxy;
  NSFileHandle *toSim;
  NSFileHandle *fromSim;
  NSMutableString *lineBuffer;
  NSInteger cursor, viewCursor, viewSpan;
  IBOutlet MOSTeletypeView *textView;
}

- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp;

- (void)typedString:(NSString*)str;
- (void)moveCursor:(NSInteger)displ;
- (void)deleteCharactersFromCursor:(NSInteger)amount;

@end
