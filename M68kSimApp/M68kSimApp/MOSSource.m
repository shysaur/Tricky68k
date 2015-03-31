//
//  Document.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import "MOSSource.h"
#import <MGSFragaria/MGSFragaria.h>
#import <MGSFragaria/SMLTextView.h>
#import <MGSFragaria/MGSFragariaPreferences.h>
#import "NSURL+TemporaryFile.h"
#import "NSUserDefaults+Archiver.h"
#import "MOSAssembler.h"
#import "MOSJobStatusManager.h"
#import "MOSSimulatorViewController.h"
#import "MOSAppDelegate.h"
#import "MOSPrintingTextView.h"


static void *AssemblageComplete = &AssemblageComplete;
static void *AssemblageEvent = &AssemblageEvent;


NSArray *MOSSyntaxErrorsFromEvents(NSArray *events) {
  NSDictionary *event;
  SMLSyntaxError *serror;
  NSMutableArray *serrors;
  
  serrors = [NSMutableArray array];
  for (event in events) {
    if ([[event objectForKey:MOSJobEventType] isEqual:MOSJobEventTypeMessage]) continue;
    if (![event objectForKey:MOSJobEventAssociatedLine]) continue;
    
    serror = [[SMLSyntaxError alloc] init];
    [serror setErrorDescription:[event objectForKey:MOSJobEventText]];
    [serror setLine:[[event objectForKey:MOSJobEventAssociatedLine] intValue]];
    
    if ([[event objectForKey:MOSJobEventType] isEqual:MOSJobEventTypeError])
      [serror setWarningLevel:kMGSErrorCategoryError];
    else
      [serror setWarningLevel:kMGSErrorCategoryWarning];
    
    [serrors addObject:serror];
  }
  return [serrors copy];
}


@implementation MOSSource


+ (void)load {
  NSUserDefaults *ud;
  
  ud = [NSUserDefaults standardUserDefaults];
  [ud registerDefaults:@{
    @"FixedEntryPoint": @YES,
    @"UseAssemblyTimeOptimization": @NO
  }];
}


+ (BOOL)autosavesInPlace {
  return YES;
}


+ (BOOL)preservesVersions {
  return YES;
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  MOSJobStatusManager *sm;
  NSString *tmp;
  NSURL *template;
  
  [super windowControllerDidLoadNib:aController];

  hadJob = NO;
  simulatorMode = NO;
  sm = [MOSJobStatusManager sharedJobStatusManger];
  [sm addObserver:self forKeyPath:@"jobList" options:NSKeyValueObservingOptionInitial context:AssemblageEvent];
  
  fragaria = [[MGSFragaria alloc] initWithView:editView];
  
  [fragaria setSyntaxDefinitionName:@"ASM-m68k"];
  [fragaria setSyntaxColoured:YES];
  [fragaria setShowsLineNumbers:YES];
  if (!text) {
    template = [[NSBundle mainBundle] URLForResource:@"VasmTemplate" withExtension:@"s"];
    tmp = [NSString stringWithContentsOfURL:template encoding:NSUTF8StringEncoding error:nil];
    text = [[NSTextStorage alloc] initWithString:tmp];
  }
  [fragaria replaceTextStorage:text];
  
  textView = [fragaria textView];
  [self setUndoManager:[textView undoManager]];
}


- (NSString *)windowNibName {
  return @"MOSSource";
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
  NSRange allRange;
  NSDictionary *opts;
  NSData *res;
  NSNumber *enc;
  
  enc = [NSNumber numberWithInteger:NSUTF8StringEncoding];
  opts = @{NSDocumentTypeDocumentOption: NSPlainTextDocumentType,
           NSCharacterEncodingDocumentAttribute: enc};
  
  allRange.length = [text length];
  allRange.location = 0;
  res = [text dataFromRange:allRange documentAttributes:opts error:outError];
  return res;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
  NSString *tmp;
  
  tmp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  if (!text)
    text = [[NSTextStorage alloc] initWithString:tmp];
  else
    [[text mutableString] setString:tmp];
  return YES;
}


- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {
  if ([anItem action] == @selector(assembleAndRun:) ||
      [anItem action] == @selector(assemble:))
    return !assembler;
  if ([anItem action] == @selector(switchToEditor:))
    return [self sourceModeSwitchAllowed];
  if ([anItem action] == @selector(switchToSimulator:))
    return [self simulatorModeSwitchAllowed];
  return [super validateUserInterfaceItem:anItem];
}


- (BOOL)simulatorModeSwitchAllowed {
  return !simulatorMode      /* mustn't be in simulator mode */
          && !assembler      /* mustn't be assembling */
          && assemblyOutput; /* must have assembled at least once */
}


- (BOOL)sourceModeSwitchAllowed {
  return simulatorMode
          && !assembler;
}


- (void)simulatorModeShouldTerminate:(id)sender {
  [self switchToEditor:sender];
  /* Keep simulator in limbo, and force re-assembly of new file for next time */
  [self willChangeValueForKey:@"simulatorModeSwitchAllowed"];
  assemblyOutput = nil;
  [self didChangeValueForKey:@"simulatorModeSwitchAllowed"];
  [[docWindow toolbar] validateVisibleItems];
}


- (CATransition *)transitionForViewSwitch {
  CATransition *res;
  
  res = [[CATransition alloc] init];
  [res setType:kCATransitionPush];
  if (simulatorMode)
    [res setSubtype:kCATransitionFromLeft];
  else
    [res setSubtype:kCATransitionFromRight];
  return res;
}


- (IBAction)switchToSimulator:(id)sender {
  NSError *err;
  NSView *contview;
  NSArray *constr;
  NSURL *oldSimExec;
  NSResponder *oldresp;
  
  if (![self simulatorModeSwitchAllowed]) return;
  
  [self willChangeValueForKey:@"simulatorModeSwitchAllowed"];
  [self willChangeValueForKey:@"sourceModeSwitchAllowed"];

  oldSimExec = [simVc simulatedExecutable];
  if (![oldSimExec isEqual:assemblyOutput]) {
    if (![simVc setSimulatedExecutable:assemblyOutput error:&err]) {
      /* Keep simulator in limbo, and force re-assembly of new file for next time */
      [self willChangeValueForKey:@"simulatorModeSwitchAllowed"];
      assemblyOutput = nil;
      [self didChangeValueForKey:@"simulatorModeSwitchAllowed"];
      [self presentError:err];
      return;
    }
    
    if (oldSimExec) unlink([oldSimExec fileSystemRepresentation]);
  }
  simView = [simVc view];
  
  constr = [editView constraints];
  [editView removeConstraints:constr];
  
  contview = [docWindow contentView];
  [contview setAnimations:@{@"subviews": [self transitionForViewSwitch]}];
  [[contview animator] replaceSubview:editView with:simView];
  [contview setAnimations:@{}];
  
  oldresp = [simView nextResponder];
  if (oldresp != simVc) {
    /* Since Yosemite, AppKit will try to do this automatically */
    [simView setNextResponder:simVc];
    [simVc setNextResponder:oldresp];
  }
  
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[simView]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(simView)]];
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[simView]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(simView)]];
  [docWindow makeFirstResponder:simView];
  
  simulatorMode = YES;
  
  [self didChangeValueForKey:@"simulatorModeSwitchAllowed"];
  [self didChangeValueForKey:@"sourceModeSwitchAllowed"];
}


- (IBAction)switchToEditor:(id)sender {
  NSView *contview;
  NSArray *constr;
  
  if (!simulatorMode) return;
  
  [self willChangeValueForKey:@"simulatorModeSwitchAllowed"];
  [self willChangeValueForKey:@"sourceModeSwitchAllowed"];
  
  constr = [editView constraints];
  [simView removeConstraints:constr];
  
  contview = [docWindow contentView];
  [contview setAnimations:@{@"subviews": [self transitionForViewSwitch]}];
  [[contview animator] replaceSubview:simView with:editView];
  [contview setAnimations:@{}];
  
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[editView]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(editView)]];
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[editView]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(editView)]];
  [docWindow makeFirstResponder:textView];
  
  simulatorMode = NO;
  
  [self didChangeValueForKey:@"simulatorModeSwitchAllowed"];
  [self didChangeValueForKey:@"sourceModeSwitchAllowed"];
}


- (IBAction)assembleAndRun:(id)sender {
  runWhenAssemblyComplete = YES;
  [self assembleInBackground];
}


- (IBAction)assemble:(id)sender {
  runWhenAssemblyComplete = NO;
  [self assembleInBackground];
}


- (void)assembleInBackground {
  if (assembler) return;
  
  [self willChangeValueForKey:@"simulatorModeSwitchAllowed"];
  [self willChangeValueForKey:@"sourceModeSwitchAllowed"];
  
  assembler = [[MOSAssembler alloc] init];
  
  tempSourceCopy = [NSURL URLWithTemporaryFilePathWithExtension:@"s"];
  
  [self saveToURL:tempSourceCopy ofType:@"public.plain-text"
  forSaveOperation:NSSaveToOperation completionHandler:^(NSError *err){
    NSUserDefaults *ud;
    MOSAssemblageOptions opts;
    MOSJobStatusManager *jsm;
    NSDictionary *jobinfo;
    NSString *title, *label;
    
    if (err) {
      assembler = nil;
      return;
    }
    [assembler addObserver:self forKeyPath:@"complete" options:0 context:AssemblageComplete];

    ud = [NSUserDefaults standardUserDefaults];
    jsm = [MOSJobStatusManager sharedJobStatusManger];
    
    assemblyOutput = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
    
    if ([self fileURL]) {
      label = [[self fileURL] lastPathComponent];
      title = [NSString stringWithFormat:NSLocalizedString(@"Assemble %@", @"Assembler job name"), label];
      jobinfo = @{MOSJobVisibleDescription: title, MOSJobAssociatedFile: [self fileURL]};
    } else {
      label = [docWindow title];
      title = [NSString stringWithFormat:NSLocalizedString(@"Assemble %@", @"Assembler job name"), label];
      jobinfo = @{MOSJobVisibleDescription: title};
    }
    
    lastJobId = [jsm addJobWithInfo:jobinfo];
    hadJob = YES;
    
    opts = [ud boolForKey:@"FixedEntryPoint"] ? MOSAssemblageOptionEntryPointFixed : MOSAssemblageOptionEntryPointSymbolic;
    opts |= [ud boolForKey:@"UseAssemblyTimeOptimization"] ? MOSAssemblageOptionOptimizationOn : MOSAssemblageOptionOptimizationOff;
    
    [assembler setOutputFile:assemblyOutput];
    [assembler setSourceFile:tempSourceCopy];
    [assembler setJobId:lastJobId];
    [assembler setAssemblageOptions:opts];
    [assembler assemble];
  }];
  
  [self didChangeValueForKey:@"simulatorModeSwitchAllowed"];
  [self didChangeValueForKey:@"sourceModeSwitchAllowed"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context {
  MOSAssemblageResult asmres;
  NSArray *events;
  MOSJobStatusManager *sm;
  
  if (context == AssemblageComplete) {
    [self willChangeValueForKey:@"simulatorModeSwitchAllowed"];
    [self willChangeValueForKey:@"sourceModeSwitchAllowed"];
    asmres = [assembler assemblageResult];
    [assembler removeObserver:self forKeyPath:@"complete" context:AssemblageComplete];
    assembler = nil;
    if (asmres == MOSAssemblageResultFailure) assemblyOutput = nil;
    [self didChangeValueForKey:@"simulatorModeSwitchAllowed"];
    [self didChangeValueForKey:@"sourceModeSwitchAllowed"];
    
    if (asmres != MOSAssemblageResultFailure && runWhenAssemblyComplete) {
      unlink([tempSourceCopy fileSystemRepresentation]);
      [self switchToSimulator:self];
      /* Since we are changing simulator executable, validation of toolbar
       * items will change, even if no events did occur. */
      [[docWindow toolbar] validateVisibleItems];
    } else {
      [(MOSAppDelegate*)[NSApp delegate] openJobsWindow:self];
    }
  } else if (context == AssemblageEvent) {
    if (!hadJob) return;
    
    sm = [MOSJobStatusManager sharedJobStatusManger];
    events = [sm eventListForJob:lastJobId];
    if (!events) {
      [fragaria setSyntaxErrors:@[]];
      hadJob = NO;
      return;
    }
    [fragaria setSyntaxErrors:MOSSyntaxErrorsFromEvents(events)];
  } else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (NSPrintInfo*)printInfo {
  NSPrintInfo *pi;
  
  pi = [super printInfo];
  [pi setHorizontalPagination:NSFitPagination];
  [pi setVerticalPagination:NSAutoPagination];
  [pi setHorizontallyCentered:NO];
  [pi setVerticallyCentered:NO];
  [pi setLeftMargin:(72.0/2.54)*1.5];
  [pi setRightMargin:(72.0/2.54)*1.5];
  [pi setTopMargin:(72.0/2.54)*2.0];
  [pi setBottomMargin:(72.0/2.54)*2.0];
  return pi;
}


- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings
  error:(NSError **)outError {
  NSPrintOperation *po;
  MOSPrintingTextView *printView;
  NSPrintInfo *printInfo;
  NSFont *font;
  NSPrintPanel *printPanel;
  NSPrintPanelOptions opts;
  NSUserDefaults *ud;
  
  ud = [NSUserDefaults standardUserDefaults];
  
  printInfo = [self printInfo];
  [[printInfo dictionary] addEntriesFromDictionary:printSettings];
  font = [ud unarchivedObjectForKey:MGSFragariaPrefsTextFont];
  
  printView = [[MOSPrintingTextView alloc] init];
  [printView setPrintInfo:printInfo];
  [printView setString:[fragaria string]];
  [printView setFont:font];
  [printView setTabWidth:[ud integerForKey:MGSFragariaPrefsTabWidth]];
  
  po = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
  [po setShowsPrintPanel:YES];
  [po setShowsProgressPanel:YES];
  printPanel = [po printPanel];
  opts = [printPanel options] | NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation;
  [printPanel setOptions:opts];
  
  return po;
}


- (void)close {
  [simView removeFromSuperviewWithoutNeedingDisplay];
  [simVc pause:self];
  simView = nil;
  simVc = nil;
  
  [super close];
}


- (void)dealloc {
  MOSJobStatusManager *sm;
  
  sm = [MOSJobStatusManager sharedJobStatusManger];
  [sm removeObserver:self forKeyPath:@"jobList" context:AssemblageEvent];
}


@end





