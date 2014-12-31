//
//  MOSSimulatorViewController.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorViewController.h"
#import "MOSSimulatorProxy.h"
#import "MOSSimDumpDataSource.h"


@implementation MOSSimulatorViewController


- (void)setSimulatedExecutable:(NSURL*)url {
  simExec = url;
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorState"];
  } @finally {}
  simProxy = [[MOSSimulatorProxy alloc] initWithExecutableURL:url];
  [simProxy addObserver:self forKeyPath:@"simulatorState" options:0 context:NULL];
  [dumpDs setSimulatorProxy:simProxy];
  NSLog(@"%@",[simProxy disassemble:5 instructionsFromLocation:0x2000]);
}


- (MOSSimulatorProxy*)simulatorProxy {
  return simProxy;
}


- (void)simulatorIsDead {
  NSWindow *pw;
  NSAlert *alert;

  pw = [[self view] window];
  alert = [[NSAlert alloc] init];
  [alert setAlertStyle:NSCriticalAlertStyle];
  [alert setMessageText:@"Simulator backend died unexpectedly"];
  [alert setInformativeText:@"This is a bug. Want to restart from scratch or you want to quit?"];
  [alert addButtonWithTitle:@"Restart"];
  [alert addButtonWithTitle:@"Close"];
  [alert beginSheetModalForWindow:pw completionHandler:^(NSModalResponse resp){
    if (resp == NSAlertFirstButtonReturn)
      [self setSimulatedExecutable:simExec];
    else
      [pw close];
  }];
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
  [dumpDs setSimulatorProxy:simProxy];
}


- (void)observeValueForKeyPath:(NSString*)keyPath    ofObject:(id)object
                        change:(NSDictionary*)change context:(void*)context {
  MOSSimulatorState newstate;
  
  newstate = [object simulatorState];
  switch (newstate) {
    case MOSSimulatorStateDead:
      [self simulatorIsDead];
      break;
      
    case MOSSimulatorStateRunning:
    case MOSSimulatorStatePaused:
      [self willChangeValueForKey:@"simulatorRunning"];
      simRunning = (newstate == MOSSimulatorStateRunning);
      [self didChangeValueForKey:@"simulatorRunning"];
      [dumpTv reloadData];
      break;
      
    default:
      break;
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


- (BOOL)isSimulatorRunning {
  return simRunning;
}


- (void)dealloc {
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorState"];
  } @finally {}
  [simProxy kill];
}


@end
