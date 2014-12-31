//
//  MOSSimulatorViewController.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorViewController.h"
#import "MOSSimulatorProxy.h"


@implementation MOSSimulatorViewController


- (void)setSimulatedExecutable:(NSURL*)url {
  simProxy = [[MOSSimulatorProxy alloc] initWithExecutableURL:url];
  NSLog(@"%@",[simProxy disassemble:5 instructionsFromLocation:0x2000]);
}


- (MOSSimulatorProxy*)simulatorProxy {
  return simProxy;
}


- (void)viewDidLoad {
  NSOpenPanel *openexe;
  
  [super viewDidLoad];
  if (!simProxy) {
    openexe = [[NSOpenPanel alloc] init];
    [openexe setAllowedFileTypes:@[@"public.executable"]];
    [openexe beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result){
      if (result == NSFileHandlingPanelOKButton) {
        [self setSimulatedExecutable:[[openexe URLs] firstObject]];
      } else {
        [[[self view] window] close];
      }
    }];
  }
}


- (IBAction)run:(id)sender {
  [simProxy run];
}


- (IBAction)stop:(id)sender {
  [simProxy stop];
}


- (IBAction)stepIn:(id)sender {
  [simProxy stepIn];
}


- (IBAction)stepOver:(id)sender {
  [simProxy stepOver];
}


- (void)dealloc {
  [simProxy kill];
}


@end
