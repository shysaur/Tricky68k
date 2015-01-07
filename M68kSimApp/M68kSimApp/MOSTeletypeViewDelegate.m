//
//  MOSTeletypeViewDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSTeletypeViewDelegate.h"
#import "MOSSimulatorProxy.h"


@implementation MOSTeletypeViewDelegate


- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp {
  simProxy = sp;
  toSim = [simProxy teletypeOutput];
  fromSim = [simProxy teletypeInput];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSData *temp;
    
    temp = [fromSim readDataOfLength:1];
    while ([temp length]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        NSString *string;
        
        string = [[NSString alloc] initWithData:temp encoding:NSISOLatin1StringEncoding];
        [self echoString:string];
      });
      temp = [fromSim readDataOfLength:1];
    }
  });
}


- (void)sendString:(NSString*)str {
  [toSim writeData:[str dataUsingEncoding:NSISOLatin1StringEncoding]];
  [self echoString:str];
}


- (void)echoString:(NSString*)str {
  NSTextStorage *ts;
  NSAttributedString *attrs;
  
  ts = [textView textStorage];
  attrs = [[NSAttributedString alloc] initWithString:str];
  [ts appendAttributedString:attrs];
}


@end
