//
//  MOSTeletypeViewDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSTeletypeViewDelegate.h"
#import "MOSSimulator.h"


@implementation MOSTeletypeViewDelegate


- (void)setSimulatorProxy:(MOSSimulator*)sp {
  MOSTeletypeView *tty;
  
  [textView setString:@""];
  [textView setFont:[self defaultMonospacedFont]];
  tty = textView;
  
  simProxy = sp;
  [simProxy setSendToTeletypeBlock:^(NSString *str){
    [tty insertOutputText:str];
  }];
}


- (void)setDefaultMonospacedFont:(NSFont *)defaultMonospacedFont {
  [super setDefaultMonospacedFont:defaultMonospacedFont];
  [textView setFont:[self defaultMonospacedFont]];
}


- (void)typedString:(NSString *)str {
  [simProxy sendToSimulator:str];
}


@end
