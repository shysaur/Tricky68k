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
#import "MOSSimDisasmDataSource.h"
#import "MOSSimRegistersDataSource.h"
#import "MOSSimStackDumpDataSource.h"
#import "MOSTeletypeViewDelegate.h"


@implementation MOSSimulatorViewController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  viewHasLoaded = NO;
  return self;
}


- (void)setSimulatedExecutable:(NSURL*)url {
  simExec = url;
  if (!viewHasLoaded) return;
  
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorState"];
  } @finally {}
  [simProxy kill];
  simProxy = [[MOSSimulatorProxy alloc] initWithExecutableURL:url];
  [simProxy addObserver:self forKeyPath:@"simulatorState"
                options:NSKeyValueObservingOptionInitial context:NULL];
  
  [dumpDs setSimulatorProxy:simProxy];
  [disasmDs setSimulatorProxy:simProxy];
  [regdumpDs setSimulatorProxy:simProxy];
  [stackDs setSimulatorProxy:simProxy];
  [ttyDelegate setSimulatorProxy:simProxy];
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
  [super viewDidLoad];
  viewHasLoaded = YES;
  
  if (!simProxy && simExec) {
    [self setSimulatedExecutable:simExec];
  }
}


- (void)viewDidAppear {
  NSOpenPanel *openexe;
  
  [super viewDidAppear];
  if (!simProxy && !simExec) {
    openexe = [[NSOpenPanel alloc] init];
    [openexe setAllowedFileTypes:@[@"public.executable"]];
    [openexe beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result){
      [openexe orderOut:nil];
      if (result == NSFileHandlingPanelOKButton) {
        [self setSimulatedExecutable:[[openexe URLs] firstObject]];
      } else {
        [[[self view] window] close];
      }
    }];
  }
}


- (void)observeValueForKeyPath:(NSString*)keyPath    ofObject:(id)object
                        change:(NSDictionary*)change context:(void*)context {
  MOSSimulatorState newstate;
  
  if (context == NULL) {
    newstate = [object simulatorState];
    switch (newstate) {
      case MOSSimulatorStateDead:
        [self simulatorIsDead];
        break;
        
      case MOSSimulatorStateRunning:
      case MOSSimulatorStatePaused:
        [self willChangeValueForKey:@"flagsStatus"];
        [self willChangeValueForKey:@"simulatorRunning"];
        simRunning = (newstate == MOSSimulatorStateRunning);
        [self didChangeValueForKey:@"flagsStatus"];
        [self didChangeValueForKey:@"simulatorRunning"];
        break;
        
      default:
        break;
    }
  } else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (IBAction)run:(id)sender {
  [simProxy run];
}


- (IBAction)pause:(id)sender {
  [simProxy stop];
}


- (IBAction)stepIn:(id)sender {
  [simProxy stepIn];
}


- (IBAction)stepOver:(id)sender {
  [simProxy stepOver];
}


- (IBAction)restart:(id)sender {
  [self setSimulatedExecutable:simExec];
}


- (BOOL)isSimulatorRunning {
  return simRunning;
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  if ([menuItem action] == @selector(run:)) return !simRunning;
  if ([menuItem action] == @selector(stepIn:)) return !simRunning;
  if ([menuItem action] == @selector(stepOver:)) return !simRunning;
  if ([menuItem action] == @selector(pause:)) return simRunning;
  return YES;
}


- (NSString *)flagsStatus {
  NSDictionary *regdump;
  uint32_t flags;
  int x, n, z, v, c;
  
  if ([simProxy simulatorState] != MOSSimulatorStatePaused) return @"";
  regdump = [simProxy registerDump];
  flags = (uint32_t)[[regdump objectForKey:MOS68kRegisterSR] integerValue];
  x = (flags & 0b10000) >> 4;
  n = (flags & 0b1000) >> 3;
  z = (flags & 0b100) >> 2;
  v = (flags & 0b10) >> 1;
  c = (flags & 0b1);
  return [NSString stringWithFormat:@"X:%d N:%d Z:%d V:%d C:%d", x, n, z, v, c];
}


- (void)dealloc {
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorState"];
  } @finally {}
  [simProxy kill];
}


@end
