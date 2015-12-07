//
//  MOSTeletypeViewDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSTeletypeViewDelegate.h"
#import "MOS68kSimulator.h"


@implementation MOSTeletypeViewDelegate


- (void)setSimulatorProxy:(MOS68kSimulator*)sp {
  MOSTeletypeView *tty;
  
  [textView setString:@""];
  [self defaultMonospacedFontHasChanged];
  tty = textView;
  
  simProxy = sp;
  [simProxy setSendToTeletypeBlock:^(NSString *str){
    [tty insertOutputText:str];
  }];
}


- (void)defaultMonospacedFontHasChanged {
  [textView setFont:[self defaultMonospacedFont]];
}


- (void)typedString:(NSString *)str {
  [simProxy sendToSimulator:str];
}


@end
