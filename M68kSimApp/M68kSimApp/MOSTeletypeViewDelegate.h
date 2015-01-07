//
//  MOSTeletypeViewDelegate.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MOSSimulatorProxy;


@interface MOSTeletypeViewDelegate : NSObject <NSTextViewDelegate> {
  MOSSimulatorProxy *simProxy;
  NSFileHandle *toSim;
  NSFileHandle *fromSim;
  NSMutableString *lineBuffer;
  IBOutlet NSTextView *textView;
}

- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp;
- (void)sendString:(NSString*)str;

@end
