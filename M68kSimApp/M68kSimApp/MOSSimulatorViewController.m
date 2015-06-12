//
//  MOSSimulatorViewController.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import "MOSSimulatorViewController.h"
#import "MOSSimulator.h"
#import "MOSSimDumpDataSource.h"
#import "MOSSimDisasmDataSource.h"
#import "MOSSimRegistersDataSource.h"
#import "MOSSimStackDumpDataSource.h"
#import "MOSTeletypeViewDelegate.h"


NSString * const MOSSimulatorViewErrorDomain = @"MOSSimulatorViewErrorDomain";


@implementation MOSSimulatorViewController


- (instancetype)initWithCoder:(NSCoder*)coder {
  self = [super initWithCoder:coder];
  viewHasLoaded = NO;
  return self;
}


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
  
  [simProxy removeAllBreakpoints];
  [self reloadSimulatedExecutable];
  
  if ([simProxy simulatorState] == MOSSimulatorStateDead) {
    if (outerr)
      *outerr = [NSError errorWithDomain:MOSSimulatorViewErrorDomain
        code:MOSSimulatorViewErrorLoadingFailed
        userInfo:@{
          NSLocalizedDescriptionKey:NSLocalizedString(@"Impossible to load "
            "this executable.", @"Loading error message title"),
          NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"This is "
            "often caused by a missing entry point, or by trying to load an "
            "executable not built for the Motorola 68000 CPU.\nTo make the "
            "entry point available, declare it as a public symbol using the "
            "\"public\" directive.", @"Generic loading error recovery "
            "suggestion")
        }];
    [simProxy removeObserver:self forKeyPath:@"simulatorState"];
    simProxy = nil;
    return NO;
  }
  return YES;
}


- (NSURL*)simulatedExecutable {
  return simExec;
}


- (void)reloadSimulatedExecutable {
  MOSSimulator *oldSimProxy;
  MOSSimulator *newSimProxy;
  NSSet *breakpoints;
  
  breakpoints = [simProxy breakpointList];
  oldSimProxy = simProxy;
  newSimProxy = [[MOSSimulator alloc] initWithExecutableURL:simExec];
  [newSimProxy addBreakpoints:breakpoints];
  [self setSimulatorProxy:newSimProxy];
  [oldSimProxy kill];
}


- (void)setSimulatorProxy:(MOSSimulator*)sp {
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorState"];
  } @finally {}
  
  simProxy = sp;
  simExec = [simProxy executableURL];
  
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


- (MOSSimulator*)simulatorProxy {
  return simProxy;
}


- (void)simulatorIsDead {
  NSWindow *pw;
  NSAlert *alert;

  pw = [[self view] window];
  alert = [[NSAlert alloc] init];
  [alert setAlertStyle:NSCriticalAlertStyle];
  [alert setMessageText:NSLocalizedString(@"Your program has died", @"Title of simulator death alert")];
  [alert setInformativeText:NSLocalizedString(@"This usually happens when your program accesses a memory area which you didn't declare with the DC or DS directives, or when a stack overflow occurs.", @"Informative text of simulator death alert")];
  [alert addButtonWithTitle:NSLocalizedString(@"Restart", @"Restart (simulator)")];
  [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
  [alert beginSheetModalForWindow:pw completionHandler:^(NSModalResponse resp){
    if (resp == NSAlertFirstButtonReturn)
      [self reloadSimulatedExecutable];
    else
      dispatch_async(dispatch_get_main_queue(), ^{
        if ([[pw delegate] respondsToSelector:@selector(simulatorModeShouldTerminate:)]) {
          id pwd = [pw delegate];
          [pwd simulatorModeShouldTerminate:self];
        } else
          [pw performClose:self];
      });
  }];
}


- (void)loadView {
  [super loadView];
  viewHasLoaded = YES;
  
  if (!simProxy)
    [NSException raise:NSInvalidArgumentException
      format:@"Simulator view can't load if no executable is associated with it."];
  [self setSimulatorForSubviewControllers];
}


- (void)observeValueForKeyPath:(NSString*)keyPath    ofObject:(id)object
                        change:(NSDictionary*)change context:(void*)context {
  MOSSimulatorState newstate;
  
  if (context == NULL) {
    newstate = [object simulatorState];
    switch (newstate) {
      case MOSSimulatorStateDead:
        [self willChangeValueForKey:@"simulatorRunning"];
        simRunning = NO;
        [self didChangeValueForKey:@"simulatorRunning"];
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
  if (!simProxy) return NO;
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
  
  if (!simProxy || [simProxy simulatorState] != MOSSimulatorStatePaused) return @"";
  regdump = [simProxy registerDump];
  flags = [[regdump objectForKey:MOS68kRegisterSR] unsignedIntValue];
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
