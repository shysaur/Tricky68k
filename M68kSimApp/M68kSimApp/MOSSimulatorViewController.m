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


- (instancetype)init {
  return [self initWithNibName:@"MOSSimulatorView" bundle:[NSBundle mainBundle]];
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  viewHasLoaded = NO;
  return self;
}


- (BOOL)setSimulatedExecutable:(NSURL*)url error:(NSError**)outerr {
  simExec = url;
  
  [self reloadSimulatedExecutable];
  
  if ([simProxy simulatorState] == MOSSimulatorStateDead) {
    if (outerr) *outerr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSExecutableNotLoadableError userInfo:nil];
    return NO;
  }
  return YES;
}


- (NSURL*)simulatedExecutable {
  return simExec;
}


- (void)reloadSimulatedExecutable {
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorState"];
  } @finally {}
  
  [simProxy kill];
  simProxy = [[MOSSimulatorProxy alloc] initWithExecutableURL:simExec];
  
  [simProxy addObserver:self forKeyPath:@"simulatorState"
                options:NSKeyValueObservingOptionInitial context:NULL];
  
  [self setSimulatorForSubviewControllers];
}


- (void)setSimulatorForSubviewControllers {
  if (!viewHasLoaded) return;
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
      [self reloadSimulatedExecutable];
    else
      [pw close];
  }];
}


- (void)loadView {
  NSResponder *oldresp;
  
  [super loadView];
  viewHasLoaded = YES;
  
  if (!simProxy)
    [NSException raise:NSInvalidArgumentException
      format:@"Simulator view can't load if no executable is associated with it."];
  [self setSimulatorForSubviewControllers];
  
  /* Install in responder chain */
  if ([[self view] nextResponder] != self) {
    /* Since Yosemite, AppKit will try to do this automatically */
    oldresp = [[self view] nextResponder];
    [[self view] setNextResponder:self];
    [self setNextResponder:oldresp];
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
  [self reloadSimulatedExecutable];
}


- (BOOL)isSimulatorRunning {
  return simRunning;
}


- (BOOL)validateUserInterfaceItem:(id)anItem {
  if ([anItem action] == @selector(run:)) return !simRunning;
  if ([anItem action] == @selector(stepIn:)) return !simRunning;
  if ([anItem action] == @selector(stepOver:)) return !simRunning;
  if ([anItem action] == @selector(pause:)) return simRunning;
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
