//
//  MOSTeletypeViewDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSTeletypeViewDelegate.h"
#import "MOSSimulatorProxy.h"


@implementation MOSTeletypeViewDelegate


- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp {
  [textView setString:@""];
  [self defaultMonospacedFontHasChanged];
  
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
        [textView insertOutputText:string];
      });
      temp = [fromSim readDataOfLength:1];
    }
  });
}


- (void)defaultMonospacedFontHasChanged {
  [textView setFont:[self defaultMonospacedFont]];
}


- (void)typedString:(NSString *)str {
  NSData *data;
  
  data = [str dataUsingEncoding:NSISOLatin1StringEncoding];
  [toSim writeData:data];
}


@end
