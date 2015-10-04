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
#import "MOSSimBrkptWindowController.h"
#import "MOSMutableBreakpoint.h"


NSString * const MOSSimulatorViewErrorDomain = @"MOSSimulatorViewErrorDomain";

static void *SimulatorState = &SimulatorState;


@implementation MOSSimulatorViewController


+ (void)load {
  NSUserDefaults *ud;
  
  ud = [NSUserDefaults standardUserDefaults];
  [ud registerDefaults:@{
    @"MaxClock": @4.0,
    @"LimitClock": @NO
  }];
}


- (instancetype)initWithCoder:(NSCoder*)coder {
  self = [super initWithCoder:coder];
  [self finishInitialization];
  return self;
}


- (instancetype)init {
  return [self initWithNibName:@"MOSSimulatorView" bundle:[NSBundle mainBundle]];
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  [self finishInitialization];
  return self;
}


- (void)finishInitialization {
  NSNotificationCenter *nc;
  __weak MOSSimulatorViewController *weakSelf = self;
  
  nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(updateSimulatorMaxClockFrequency) name:NSUserDefaultsDidChangeNotification object:nil];
  
  viewHasLoaded = NO;
  
  clockUpdateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
    dispatch_get_main_queue());
  dispatch_source_set_event_handler(clockUpdateTimer, ^{
    MOSSimulatorViewController *strongSelf;
    
    strongSelf = weakSelf;
    [strongSelf updateClockFrequencyDisplay];
    strongSelf = nil;
  });
  dispatch_source_set_timer(clockUpdateTimer, DISPATCH_TIME_FOREVER, 0, 0);
  dispatch_resume(clockUpdateTimer);
}


- (BOOL)setSimulatedExecutable:(NSURL*)url error:(NSError**)outerr {
  NSError *tmpe;
  
  simExec = url;
  
  [simProxy removeAllBreakpoints];
  tmpe = [self reloadSimulatedExecutable];
  
  if (tmpe) {
    if (outerr) *outerr = tmpe;
    [simProxy removeObserver:self forKeyPath:@"simulatorState"];
    simProxy = nil;
    return NO;
  }
  return YES;
}


- (NSURL*)simulatedExecutable {
  return simExec;
}


- (NSError *)reloadSimulatedExecutable {
  MOSSimulator *oldSimProxy;
  MOSSimulator *newSimProxy;
  NSSet *breakpoints;
  NSError *res;
  
  breakpoints = [simProxy breakpointList];
  oldSimProxy = simProxy;
  newSimProxy = [[MOSSimulator alloc] initWithExecutableURL:simExec error:&res];
  [newSimProxy addBreakpoints:breakpoints];
  [self setSimulatorProxy:newSimProxy];
  [oldSimProxy kill];
  exceptionOccurred = NO;
  
  return res;
}


- (void)setSimulatorProxy:(MOSSimulator*)sp {
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorState"];
  } @finally {}
  
  simProxy = sp;
  simExec = [simProxy executableURL];
  [self updateSimulatorMaxClockFrequency];
  
  [simProxy addObserver:self forKeyPath:@"simulatorState"
    options:NSKeyValueObservingOptionInitial context:SimulatorState];
  
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
  NSAlert *alert;
  NSWindow *pw;
  NSError *err;
  
  if ((err = [simProxy lastSimulatorException])) {
    alert = [NSAlert alertWithError:err];
  } else {
    alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"The simulator has died", @"Title "
      "of simulator death alert")];
    [alert setInformativeText:NSLocalizedString(@"An unexpected condition "
      "occurred which caused the simulator to crash. Try restarting and see "
      "what happens.", @"Informative text of simulator death alert")];
  }
  [alert setAlertStyle:NSCriticalAlertStyle];
  [alert addButtonWithTitle:NSLocalizedString(@"Restart", @"Restart (simulator)")];
  [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
  
  pw = [[self view] window];
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


- (void)simulatorExceptionOccurred {
  NSWindow *pw;
  NSAlert *alert;
  NSError *err;
  
  exceptionOccurred = YES;
  err = [simProxy lastSimulatorException];
  alert = [NSAlert alertWithError:err];
  [alert setAlertStyle:NSCriticalAlertStyle];
  [alert addButtonWithTitle:NSLocalizedString(@"Debug", @"Debug (after "
    "segmentation fault)")];
  
  pw = [[self view] window];
  [alert beginSheetModalForWindow:pw completionHandler:nil];
}


- (void)loadView {
  [super loadView];
  viewHasLoaded = YES;
  
  if (!simProxy)
    [NSException raise:NSInvalidArgumentException format:@"Simulator view "
      "can't load if no executable is associated with it."];
  [self setSimulatorForSubviewControllers];
}


- (void)observeValueForKeyPath:(NSString*)keyPath    ofObject:(id)object
                        change:(NSDictionary*)change context:(void*)context {
  MOSSimulatorState newstate;
  NSError *exc;
  
  if (context == SimulatorState) {
    newstate = [object simulatorState];
    switch (newstate) {
      case MOSSimulatorStateDead:
        [self willChangeValueForKey:@"simulatorRunning"];
        simRunning = NO;
        [self didChangeValueForKey:@"simulatorRunning"];
        [self simulatorIsDead];
        break;
        
      case MOSSimulatorStatePaused:
        stepping = NO;
        dispatch_source_set_timer(clockUpdateTimer, DISPATCH_TIME_FOREVER, 0, 0);
        exc = [simProxy lastSimulatorException];
      case MOSSimulatorStateRunning:
        [self willChangeValueForKey:@"flagsStatus"];
        [self willChangeValueForKey:@"simulatorRunning"];
        simRunning = (newstate == MOSSimulatorStateRunning);
        [self didChangeValueForKey:@"flagsStatus"];
        [self didChangeValueForKey:@"simulatorRunning"];
        if (newstate == MOSSimulatorStatePaused) {
          if (exc) {
            [self simulatorExceptionOccurred];
          }
          [self updateClockFrequencyDisplay];
        } else if (newstate == MOSSimulatorStateRunning) {
          dispatch_source_set_timer(clockUpdateTimer, dispatch_time(
            DISPATCH_TIME_NOW, NSEC_PER_SEC/2), NSEC_PER_SEC, NSEC_PER_SEC/4);
        }
        break;
        
      default:
        break;
    }
  } else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (void)updateSimulatorMaxClockFrequency {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if ([ud boolForKey:@"LimitClock"])
    [simProxy setMaximumClockFrequency:[ud doubleForKey:@"MaxClock"]];
  else
    [simProxy setMaximumClockFrequency:0];
}


- (void)updateClockFrequencyDisplay {
  static NSNumberFormatter *nf;
  static NSString *mhzFmt;
  NSString *tmp;
  float mhz;
  
  if (!nf) {
    nf = [[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    [nf setUsesGroupingSeparator:NO];
  }
  if (!mhzFmt) {
    mhzFmt = NSLocalizedString(@"%@ MHz", @"Clock frequency badge format (MHz)");
  }
  
  if (simRunning && !stepping) {
    mhz = [simProxy clockFrequency];
    if (mhz >= 0) {
      if (mhz >= 1000.0) {
        [nf setMinimumFractionDigits:0];
        [nf setMaximumFractionDigits:0];
      } else {
        [nf setMinimumFractionDigits:1];
        [nf setMaximumFractionDigits:1];
      }
      tmp = [NSString stringWithFormat:mhzFmt, [nf stringFromNumber:@(mhz)]];
    } else
      tmp = @"";
    [self setClockFrequency:tmp];
  } else {
    [self setClockFrequency:@""];
  }
}


- (void)setClockFrequency:(NSString *)str {
  clockFreq = str;
}


- (NSString *)clockFrequency {
  return clockFreq;
}


- (IBAction)run:(id)sender {
  [simProxy run];
}


- (IBAction)pause:(id)sender {
  [simProxy stop];
}


- (IBAction)stepIn:(id)sender {
  stepping = YES;
  [simProxy stepIn];
}


- (IBAction)stepOver:(id)sender {
  stepping = YES;
  [simProxy stepOver];
}


- (IBAction)restart:(id)sender {
  [self reloadSimulatedExecutable];
}


- (IBAction)openBreakpointsWindow:(id)sender {
  NSWindow *w;
  
  if (!brkptWc) {
    brkptWc = [[MOSSimBrkptWindowController alloc] init];
  }
  [brkptWc setBreakpointsFromSet:[simProxy breakpointList]];
  
  w = [[self view] window];
  [brkptWc beginSheetModalForWindow:w completionHandler:^(NSModalResponse res) {
    NSArray *bpts;
    MOSMutableBreakpoint *mb;
    
    if (res == NSModalResponseOK) {
      [simProxy removeAllBreakpoints];
      bpts = [brkptWc displayedBreakpoints];
      for (mb in bpts) {
        [simProxy addBreakpointAtAddress:[mb rawAddress]];
      }
      [disasmDs dataHasChanged];
    }
  }];
}


- (BOOL)isSimulatorRunning {
  return simRunning;
}


- (BOOL)validateUserInterfaceItem:(id)anItem {
  if (!simProxy || [simProxy isSimulatorDead]) return NO;
  
  if ([anItem action] == @selector(run:) ||
      [anItem action] == @selector(stepIn:) ||
      [anItem action] == @selector(stepOver:) ||
      [anItem action] == @selector(openBreakpointsWindow:)
     )
    return !simRunning && !exceptionOccurred;
  
  if ([anItem action] == @selector(pause:))
    return simRunning && !exceptionOccurred;
  
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
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorState"];
  } @finally {}
  [nc removeObserver:self];
  clockUpdateTimer = nil;
  [simProxy kill];
}


@end
