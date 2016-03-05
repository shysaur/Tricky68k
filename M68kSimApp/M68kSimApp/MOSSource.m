//
//  Document.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import "MOSSource.h"
#import <Fragaria/Fragaria.h>
#import "MOSFragariaPreferencesObserver.h"
#import "NSURL+TemporaryFile.h"
#import "NSUserDefaults+Archiver.h"
#import "MOS68kAssembler.h"
#import "MOS68kSimulator.h"
#import "MOS68kSimulatorPresentation.h"
#import "MOSJobStatusManager.h"
#import "MOSJob.h"
#import "MOSSimulatorViewController.h"
#import "MOSAppDelegate.h"
#import "MOSPrintingTextView.h"
#import "MOSFragariaPreferencesObserver.h"
#import "MOSPlatform.h"
#import "MOSSourceBreakpointDelegate.h"
#import "MOSListingDictionary.h"


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


#pragma mark - Class Properties


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


#pragma mark - Initialization


- (instancetype)init {
  self = [super init];
  platform = [MOSPlatform platformWithAssemblerClass:[MOS68kAssembler class]
    simulatorClass:[MOS68kSimulator class]
    presentationClass:[MOS68kSimulatorPresentation class]
    localizedName:@"Motorola 68000"];
  return self;
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  NSString *tmp;
  NSURL *template;
  BOOL fixtabs;
  
  [super windowControllerDidLoadNib:aController];

  hadJob = NO;
  simulatorMode = NO;
  
  if (!text) {
    template = [[NSBundle mainBundle] URLForResource:@"VasmTemplate" withExtension:@"s"];
    tmp = [NSString stringWithContentsOfURL:template encoding:NSUTF8StringEncoding error:nil];
    text = [[NSTextStorage alloc] initWithString:tmp];
    fixtabs = YES;
  } else
    fixtabs = NO;
  
  [fragaria replaceTextStorage:text];
  
  prefobs = [[MOSFragariaPreferencesObserver alloc] initWithFragaria:fragaria];
  
  [fragaria setSyntaxDefinitionName:@"ASM-m68k"];
  [fragaria setSyntaxColoured:YES];
  [fragaria setShowsLineNumbers:YES];
  
  textView = [fragaria textView];
  [self setUndoManager:[textView undoManager]];
  
  if (fixtabs && [fragaria indentWithSpaces]) {
    [textView selectAll:self];
    [textView performDetabWithNumberOfSpaces:[fragaria tabWidth]];
    [textView setSelectedRange:NSMakeRange(0, 0)];
  }
  [[textView undoManager] removeAllActions];
  
  if ([[platform assemblerClass] instancesRespondToSelector:@selector(listingDictionary)])
    breakptdel = [[MOSSourceBreakpointDelegate alloc] initWithFragaria:fragaria];
}


- (NSString *)windowNibName {
  return @"MOSSource";
}


#pragma mark - Document Management


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


- (MOSPlatform *)currentPlatform {
  return platform;
}


#pragma mark - View Switch


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
  CAMediaTimingFunction *tim;
  
  res = [[CATransition alloc] init];
  [res setType:kCATransitionPush];
  if (simulatorMode)
    [res setSubtype:kCATransitionFromLeft];
  else
    [res setSubtype:kCATransitionFromRight];
  tim = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
  [res setTimingFunction:tim];
  return res;
}


- (IBAction)switchToSimulator:(id)sender {
  NSError *err;
  NSView *contview;
  NSURL *oldSimExec;
  NSResponder *oldresp;
  Class simType;
  NSSet *bp;
  
  if (![self simulatorModeSwitchAllowed])
    return;
  
  [self willChangeValueForKey:@"simulatorModeSwitchAllowed"];
  [self willChangeValueForKey:@"sourceModeSwitchAllowed"];

  oldSimExec = [simVc simulatedExecutable];
  if (![oldSimExec isEqual:assemblyOutput]) {
    simType = [platform simulatorClass];
    if (![simVc setSimulatedExecutable:assemblyOutput simulatorType:simType error:&err]) {
      /* Keep simulator in limbo, and force re-assembly of new file for next time */
      [self willChangeValueForKey:@"simulatorModeSwitchAllowed"];
      assemblyOutput = nil;
      [self didChangeValueForKey:@"simulatorModeSwitchAllowed"];
      [self presentError:err];
      return;
    }
    
    if (oldSimExec)
      unlink([oldSimExec fileSystemRepresentation]);
  }
  
  if (lastListing) {
    bp = [breakptdel breakpointAddressesWithListingDictionary:lastListing];
    [simVc replaceBreakpoints:bp];
  }
  
  simView = [simVc view];
  
  contview = [docWindow contentView];
  [contview setAnimations:@{@"subviews": [self transitionForViewSwitch]}];
  [[contview animator] replaceSubview:fragaria with:simView];
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
  NSSet *bp;
  
  if (!simulatorMode)
    return;
  
  if (lastListing) {
    bp = [[simVc simulatorProxy] breakpointList];
    [breakptdel syncBreakpointsWithAddresses:bp listingDictionary:lastListing];
  }
  
  [self willChangeValueForKey:@"simulatorModeSwitchAllowed"];
  [self willChangeValueForKey:@"sourceModeSwitchAllowed"];
  
  contview = [docWindow contentView];
  [contview setAnimations:@{@"subviews": [self transitionForViewSwitch]}];
  [[contview animator] replaceSubview:simView with:fragaria];
  [contview setAnimations:@{}];
  
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[fragaria]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(fragaria)]];
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[fragaria]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(fragaria)]];
  [docWindow makeFirstResponder:textView];
  
  simulatorMode = NO;
  
  [self didChangeValueForKey:@"simulatorModeSwitchAllowed"];
  [self didChangeValueForKey:@"sourceModeSwitchAllowed"];
}


#pragma mark - Assemblage


- (IBAction)assembleAndRun:(id)sender {
  runWhenAssemblyComplete = YES;
  [self assembleInBackground];
}


- (IBAction)assemble:(id)sender {
  runWhenAssemblyComplete = NO;
  [self assembleInBackground];
}


- (IBAction)assembleAndSaveAs:(id)sender {
  NSSavePanel *sp;
  
  sp = [NSSavePanel savePanel];
  [sp setAllowedFileTypes:@[@"o"]];
  [sp setAllowsOtherFileTypes:YES];
  [sp setCanSelectHiddenExtension:YES];
  [sp beginSheetModalForWindow:docWindow completionHandler:^(NSInteger result){
    if (result == NSFileHandlingPanelOKButton) {
      runWhenAssemblyComplete = NO;
      [self assembleInBackgroundToURL:[sp URL] listingURL:nil];
    }
  }];
}


- (void)assembleInBackground {
  assemblyOutput = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
  if (breakptdel)
    listingOutput = [NSURL URLWithTemporaryFilePathWithExtension:@"lst"];
  else
    listingOutput = nil;
  
  [self assembleInBackgroundToURL:assemblyOutput listingURL:listingOutput];
}


- (void)assembleInBackgroundToURL:(NSURL *)outurl listingURL:(NSURL *)listurl {
  if (assembler) return;
  
  [self setTransient:NO];
  
  [self willChangeValueForKey:@"simulatorModeSwitchAllowed"];
  [self willChangeValueForKey:@"sourceModeSwitchAllowed"];
  
  assembler = [[[platform assemblerClass] alloc] init];
  
  tempSourceCopy = [NSURL URLWithTemporaryFilePathWithExtension:@"s"];
  
  [self saveToURL:tempSourceCopy ofType:@"public.plain-text"
  forSaveOperation:NSSaveToOperation completionHandler:^(NSError *err){
    NSUserDefaults *ud;
    MOSAssemblageOptions opts;
    MOSJobStatusManager *jsm;
    NSString *title, *label;
    
    if (err) {
      assembler = nil;
      if (runWhenAssemblyComplete)
        assemblyOutput = nil;
      return;
    }
    [assembler addObserver:self forKeyPath:@"complete" options:0 context:AssemblageComplete];

    ud = [NSUserDefaults standardUserDefaults];
    jsm = [MOSJobStatusManager sharedJobStatusManger];
    
    if (lastJob)
      [lastJob removeObserver:self forKeyPath:@"events" context:AssemblageEvent];
    lastJob = [[MOSJob alloc] init];
    [lastJob addObserver:self forKeyPath:@"events" options:NSKeyValueObservingOptionInitial context:AssemblageEvent];
    
    if ([self fileURL]) {
      label = [[self fileURL] lastPathComponent];
      title = [NSString stringWithFormat:NSLocalizedString(@"Assemble %@", @"Assembler job name"), label];
      [lastJob setAssociatedFile:[self fileURL]];
    } else {
      label = [docWindow title];
      title = [NSString stringWithFormat:NSLocalizedString(@"Assemble %@", @"Assembler job name"), label];
    }
    [lastJob setVisibleDescription:title];
    
    [jsm addJob:lastJob];
    hadJob = YES;
    
    opts = [ud boolForKey:@"FixedEntryPoint"] ? MOSAssemblageOptionEntryPointFixed : MOSAssemblageOptionEntryPointSymbolic;
    opts |= [ud boolForKey:@"UseAssemblyTimeOptimization"] ? MOSAssemblageOptionOptimizationOn : MOSAssemblageOptionOptimizationOff;
    
    [assembler setOutputFile:outurl];
    if (listurl)
      [assembler setOutputListingFile:listurl];
    [assembler setSourceFile:tempSourceCopy];
    [assembler setJobStatus:lastJob];
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
  
  if (context == AssemblageComplete) {
    [self willChangeValueForKey:@"simulatorModeSwitchAllowed"];
    [self willChangeValueForKey:@"sourceModeSwitchAllowed"];
    asmres = [assembler assemblageResult];
    if ([assembler respondsToSelector:@selector(listingDictionary)])
      lastListing = [assembler listingDictionary];
    else
      lastListing = nil;
    [assembler removeObserver:self forKeyPath:@"complete" context:AssemblageComplete];
    assembler = nil;
    if (asmres == MOSAssemblageResultFailure) assemblyOutput = nil;
    [self didChangeValueForKey:@"simulatorModeSwitchAllowed"];
    [self didChangeValueForKey:@"sourceModeSwitchAllowed"];
    
    if (asmres != MOSAssemblageResultFailure && runWhenAssemblyComplete) {
      unlink([tempSourceCopy fileSystemRepresentation]);
      if (listingOutput)
        unlink([listingOutput fileSystemRepresentation]);
      [self switchToSimulator:self];
      /* Since we are changing simulator executable, validation of toolbar
       * items will change, even if no events did occur. */
      [[docWindow toolbar] validateVisibleItems];
    } else {
      [(MOSAppDelegate*)[NSApp delegate] openJobsWindow:self];
    }
  } else if (context == AssemblageEvent) {
    if (!hadJob) return;
    
    events = [lastJob events];
    if (!events) {
      [fragaria setSyntaxErrors:@[]];
      hadJob = NO;
      return;
    }
    [fragaria setSyntaxErrors:MOSSyntaxErrorsFromEvents(events)];
  } else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


#pragma mark - Print


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


#pragma mark - Finalization


- (void)close {
  [simView removeFromSuperviewWithoutNeedingDisplay];
  [simVc pause:self];
  simView = nil;
  simVc = nil;
  
  [super close];
}


- (void)dealloc {
  if (lastJob)
    [lastJob removeObserver:self forKeyPath:@"events" context:AssemblageEvent];
}


@end





