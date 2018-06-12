//
//  Document.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import "MOSSourceDocument.h"
#import <Fragaria/Fragaria.h>
#import "PlatformSupport.h"
#import "MOSFragariaPreferencesObserver.h"
#import "MOSJobStatusManager.h"
#import "MOSSimulatorViewController.h"
#import "MOSAppDelegate.h"
#import "MOSPrintingTextView.h"
#import "MOSFragariaPreferencesObserver.h"
#import "MOSSourceBreakpointDelegate.h"
#import "MOSListingDictionary.h"
#import "MOSPrintAccessoryViewController.h"
#import "MOSPlatformManager.h"
#import "MOSSimulatorTouchBarDelegate.h"


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


@interface MOSSourceDocument ()

@property (nonatomic) BOOL simulatorMode;

@property (nonatomic) MOSAssembler *assembler;
@property (nonatomic) MOSExecutable *assemblyOutput;

@property (nonatomic) MOSSimulatorTouchBarDelegate *touchBarDelegate;

@end


@implementation MOSSourceDocument


#pragma mark - Class Properties


+ (BOOL)autosavesInPlace {
  return YES;
}


+ (BOOL)preservesVersions {
  return YES;
}


#pragma mark - Initialization


- (instancetype)init {
  self = [super init];
  platform = [[MOSPlatformManager sharedManager] defaultPlatform];
  return self;
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  NSString *tmp;
  NSURL *template;
  BOOL fixtabs;
  
  [super windowControllerDidLoadNib:aController];

  hadJob = NO;
  self.simulatorMode = NO;
  
  if (!text) {
    template = [platform editorTemplate];
    tmp = [NSString stringWithContentsOfURL:template encoding:NSUTF8StringEncoding error:nil];
    text = [[NSTextStorage alloc] initWithString:tmp];
    fixtabs = YES;
  } else
    fixtabs = NO;
  
  [fragaria replaceTextStorage:text];
  
  prefobs = [[MOSFragariaPreferencesObserver alloc] initWithFragaria:fragaria];
  
  [fragaria setSyntaxDefinitionName:[platform syntaxDefinitionName]];
  [fragaria setSyntaxColoured:YES];
  [fragaria setShowsLineNumbers:YES];
  
  textView = [fragaria textView];
  [self setUndoManager:[textView undoManager]];
  
  if ([textView respondsToSelector:@selector(setTouchBar:)]) {
    NSTouchBar *dummytb = [[NSTouchBar alloc] init];
    dummytb.defaultItemIdentifiers = @[];
    [textView setTouchBar:dummytb];
  }
  
  if (fixtabs && [fragaria indentWithSpaces]) {
    [textView selectAll:self];
    [textView performDetabWithNumberOfSpaces:[fragaria tabWidth]];
    [textView setSelectedRange:NSMakeRange(0, 0)];
  }
  [[textView undoManager] removeAllActions];
  
  if ([[platform assemblerClass] instancesRespondToSelector:@selector(listingDictionary)])
    breakptdel = [[MOSSourceBreakpointDelegate alloc] initWithFragaria:fragaria source:self];
}


- (NSString *)windowNibName {
  return @"MOSSourceDocument";
}


- (NSTouchBar *)makeTouchBar {
  if (self.touchBarDelegate == nil) {
    [self setTouchBarDelegate:[[MOSSimulatorTouchBarDelegate alloc] init]];
    [self.touchBarDelegate setSimulatorViewController:simVc];
    [self.touchBarDelegate setSourceDocument:self];
  }
  return [self.touchBarDelegate makeSourceDocumentTouchBar];
}


#pragma mark - Document Management


- (NSArray<NSString *> *)writableTypesForSaveOperation:(NSSaveOperationType)so {
  if (so == NSSaveAsOperation || so == NSSaveToOperation) {
    return @[@"com.danielecattaneo.assembly-source", @"public.plain-text"];
  }
  return [super writableTypesForSaveOperation:so];
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
    return !self.assembler;
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


+ (NSSet *)keyPathsForValuesAffectingSimulatorModeSwitchAllowed {
  return [NSSet setWithObjects:@"simulatorMode", @"assembler", @"assemblyOutput", nil];
}


- (BOOL)simulatorModeSwitchAllowed {
  return !self.simulatorMode      /* mustn't be in simulator mode */
          && !self.assembler      /* mustn't be assembling */
          && self.assemblyOutput; /* must have assembled at least once */
}


+ (NSSet *)keyPathsForValuesAffectingSourceModeSwitchAllowed {
  return [NSSet setWithObjects:@"simulatorMode", @"assembler", nil];
}


- (BOOL)sourceModeSwitchAllowed {
  return self.simulatorMode
          && !self.assembler;
}


- (void)simulatorModeShouldTerminate:(id)sender {
  [self switchToEditor:sender];
  /* Keep simulator in limbo, and force re-assembly of new file for next time */
  self.assemblyOutput = nil;
  [[docWindow toolbar] validateVisibleItems];
}


- (CATransition *)transitionForViewSwitch {
  CATransition *res;
  CAMediaTimingFunction *tim;
  
  res = [[CATransition alloc] init];
  [res setType:kCATransitionPush];
  if (self.simulatorMode)
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
  NSResponder *oldresp;
  Class simType;
  
  if (![self simulatorModeSwitchAllowed])
    return;

  if ([simVc simulatedExecutable] != self.assemblyOutput) {
    simType = [platform simulatorClass];
    if (![simVc setSimulatedExecutable:self.assemblyOutput simulatorType:simType
          withSourceCode:lastSource assembledToListing:lastListing error:&err]) {
      /* Keep simulator in limbo, and force re-assembly of new file for next time */
      self.assemblyOutput = nil;
      [self presentDocumentModalError:err];
      return;
    }
  }
  
  [self breakpointsShouldSyncToSimulator:nil];
  
  simView = [simVc view];
  
  [docWindow makeFirstResponder:nil];
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
  if (!lastSimViewFirstResponder)
    [docWindow makeFirstResponder:simView];
  else
    [docWindow makeFirstResponder:lastSimViewFirstResponder];
  
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[simView]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(simView)]];
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[simView]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(simView)]];
  
  self.simulatorMode = YES;
}


- (IBAction)switchToEditor:(id)sender {
  NSView *contview;
  id oldresp;
  
  if (!self.simulatorMode)
    return;
  
  [self breakpointsShouldSyncFromSimulator:nil];
  
  lastSimViewFirstResponder = [docWindow firstResponder];
  [docWindow makeFirstResponder:nil];
  contview = [docWindow contentView];
  [contview setAnimations:@{@"subviews": [self transitionForViewSwitch]}];
  [[contview animator] replaceSubview:simView with:fragaria];
  [contview setAnimations:@{}];
  
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[fragaria]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(fragaria)]];
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[fragaria]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(fragaria)]];
  
  oldresp = [fragaria nextResponder];
  if (oldresp != simVc) {
    /* Put the simulator view controller back in the responder chain to keep
     * simulator-related menu items working */
    [fragaria setNextResponder:simVc];
    [simVc setNextResponder:oldresp];
  }
  [docWindow makeFirstResponder:textView];
  
  self.simulatorMode = NO;
}


#pragma mark - Assemblage


- (IBAction)assembleAndRun:(id)sender {
  if (self.simulatorMode)
    [self switchToEditor:nil];
  [self assembleInBackgroundWithCompletionHandler:^(MOSAssemblageResult asmres) {
    if (asmres != MOSAssemblageResultFailure) {
      [self switchToSimulator:self];
      /* Since we are changing simulator executable, validation of toolbar
       * items will change, even if no events did occur. */
      [[self->docWindow toolbar] validateVisibleItems];
    } else {
      [(MOSAppDelegate*)[NSApp delegate] openJobsWindow:self];
    }
  }];
}


- (IBAction)assemble:(id)sender {
  if (self.simulatorMode)
    [self switchToEditor:nil];
  [self assembleInBackgroundWithCompletionHandler:^(MOSAssemblageResult asmres) {
    [(MOSAppDelegate*)[NSApp delegate] openJobsWindow:self];
  }];
}


- (IBAction)assembleAndSaveAs:(id)sender {
  NSSavePanel *sp;
  
  sp = [NSSavePanel savePanel];
  [sp setAllowedFileTypes:@[@"o"]];
  [sp setAllowsOtherFileTypes:YES];
  [sp setCanSelectHiddenExtension:YES];
  [sp beginSheetModalForWindow:docWindow completionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelOKButton) {
      self->assembleForSaveOnly = YES;
      
      [self assembleInBackgroundWithListing:NO completionHandler:^void
      (MOSAssemblageResult asmres, MOSExecutable *exc, MOSListingDictionary *ld) {
        if (!exc) {
          [(MOSAppDelegate*)[NSApp delegate] openJobsWindow:self];
          return;
        }
        NSError *err;
        if (![exc writeToURL:sp.URL error:&err])
          [self presentDocumentModalError:err];
      }];
    }
  }];
}


- (void)assembleInBackgroundWithCompletionHandler:(void(^)(MOSAssemblageResult
  asmres))completionHandler
{
  assembleForSaveOnly = NO;
  self.assemblyOutput = nil;
  
  [self assembleInBackgroundWithListing:!!breakptdel completionHandler:^void
  (MOSAssemblageResult asmres, MOSExecutable *exc, MOSListingDictionary *ld) {
    self.assemblyOutput = exc;
    self->lastListing = ld;
    completionHandler(asmres);
  }];
}


- (void)assembleInBackgroundWithListing:(BOOL)wlist completionHandler:(void (^)
  (MOSAssemblageResult result, MOSExecutable *exc, MOSListingDictionary *ld))
  completionHandler
{
  MOSAssemblageOptions opts;
  MOSJobStatusManager *jsm;
  NSString *title, *label;
  
  if (self.assembler)
    return;
  
  [self setTransient:NO];
  
  self.assembler = [[[platform assemblerClass] alloc] init];
  opts = [platform currentAssemblageOptions];
  
  NSString *sourceToAssemble;
  if (!assembleForSaveOnly) {
    lastSource = [[NSTextStorage alloc] initWithAttributedString:text];
    sourceToAssemble = [lastSource mutableString];
  } else {
    sourceToAssemble = [[text string] copy];
  }

  jsm = [MOSJobStatusManager sharedJobStatusManger];
  
  if (lastJob)
    [lastJob removeObserver:self forKeyPath:@"events" context:AssemblageEvent];
  lastJob = [[MOSJob alloc] init];
  [lastJob addObserver:self forKeyPath:@"events"
    options:NSKeyValueObservingOptionInitial context:AssemblageEvent];
  
  if ([self fileURL]) {
    label = [[self fileURL] lastPathComponent];
    title = [NSString stringWithFormat:NSLocalizedString(@"Assemble %@",
      @"Assembler job name"), label];
    [lastJob setAssociatedFile:[self fileURL]];
  } else {
    label = [docWindow title];
    title = [NSString stringWithFormat:NSLocalizedString(@"Assemble %@",
      @"Assembler job name"), label];
  }
  [lastJob setVisibleDescription:title];
  
  [jsm addJob:lastJob];
  hadJob = YES;
  
  if ([self.assembler respondsToSelector:@selector(listingDictionary)])
    [self.assembler setProduceListingDictionary:wlist];
  [self.assembler setSourceCode:sourceToAssemble];
  [self.assembler setJobStatus:lastJob];
  [self.assembler setAssemblageOptions:opts];
  
  [self.assembler assembleWithCompletionHandler:^{
    MOSAssemblageResult asmres = [self.assembler assemblageResult];
    
    MOSExecutable *exc;
    MOSListingDictionary *list;
    if (asmres != MOSAssemblageResultFailure) {
      exc = [self.assembler output];
      if ([self.assembler respondsToSelector:@selector(listingDictionary)] && wlist)
        list = [self.assembler listingDictionary];
      else
        list = nil;
    }
    
    self.assembler = nil;
    completionHandler(asmres, exc, list);
  }];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context {
  NSArray *events;
  
  if (context == AssemblageEvent) {
    if (!hadJob || assembleForSaveOnly)
      return;
    
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


#pragma mark - Breakpoints


- (void)breakpointsShouldSyncFromSimulator:(id)sender {
  NSSet *bp;
  
  if (lastListing) {
    bp = [[simVc simulatorProxy] breakpointList];
    [breakptdel syncBreakpointsWithAddresses:bp listingDictionary:lastListing];
  }
}


- (void)breakpointsShouldSyncToSimulator:(id)sender {
  NSSet *bp;
  
  if (lastListing) {
    bp = [breakptdel breakpointAddressesWithListingDictionary:lastListing];
    [simVc replaceBreakpoints:bp];
  }
}


#pragma mark - Print


- (NSPrintInfo*)printInfo {
  NSPrintInfo *pi;
  NSFont *font;
  NSUserDefaults *ud;
  
  ud = [NSUserDefaults standardUserDefaults];
  
  pi = [super printInfo];
  [pi setHorizontalPagination:NSFitPagination];
  [pi setVerticalPagination:NSAutoPagination];
  [pi setHorizontallyCentered:NO];
  [pi setVerticallyCentered:NO];
  [pi setLeftMargin:(72.0/2.54)*1.5];
  [pi setRightMargin:(72.0/2.54)*1.5];
  [pi setTopMargin:(72.0/2.54)*2.0];
  [pi setBottomMargin:(72.0/2.54)*2.0];
  
  font = [ud unarchivedObjectForKey:MOSDefaultsPrintFont];
  if (!font)
    font = [ud unarchivedObjectForKey:MGSFragariaPrefsTextFont];
  [pi.dictionary setObject:font forKey:@"MOSFont"];
  
  return pi;
}


- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings
  error:(NSError **)outError {
  NSPrintOperation *po;
  MOSPrintingTextView *printView;
  NSPrintInfo *printInfo;
  NSPrintPanel *printPanel;
  NSPrintPanelOptions opts;
  NSUserDefaults *ud;
  MOSPrintAccessoryViewController *pa;
  
  ud = [NSUserDefaults standardUserDefaults];
  
  printInfo = [self printInfo];
  [[printInfo dictionary] addEntriesFromDictionary:printSettings];
  
  printView = [[MOSPrintingTextView alloc] init];
  [printView setString:[fragaria string]];
  [printView setTabWidth:[ud integerForKey:MGSFragariaPrefsTabWidth]];
  
  pa = [[MOSPrintAccessoryViewController alloc] init];
  [pa setRepresentedObject:printInfo];
  
  po = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
  [po setShowsPrintPanel:YES];
  [po setShowsProgressPanel:YES];
  printPanel = [po printPanel];
  opts = [printPanel options] | NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation;
  [printPanel setOptions:opts];
  [printPanel addAccessoryController:pa];
  
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





