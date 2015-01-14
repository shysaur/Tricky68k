//
//  Document.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import "MOSSource.h"
#import <MGSFragaria/MGSFragaria.h>
#import "NSURL+TemporaryFile.h"
#import "MOSAssembler.h"
#import "MOSJobStatusManager.h"
#import "MOSSimulatorViewController.h"


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
    [serror setDescription:[event objectForKey:MOSJobEventText]];
    [serror setLine:[[event objectForKey:MOSJobEventAssociatedLine] intValue]+1];
    [serrors addObject:serror];
  }
  return [serrors copy];
}


@implementation MOSSource


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  MOSJobStatusManager *sm;
  
  [super windowControllerDidLoadNib:aController];

  hadJob = NO;
  simulatorMode = NO;
  sm = [MOSJobStatusManager sharedJobStatusManger];
  [sm addObserver:self forKeyPath:@"jobList" options:NSKeyValueObservingOptionInitial context:AssemblageEvent];
  
  fragaria = [[MGSFragaria alloc] init];
  [fragaria setObject:self forKey:MGSFODelegate];
  [fragaria embedInView:editView];
  
  [fragaria setObject:@"VASM Motorola 68000 Assembly" forKey:MGSFOSyntaxDefinitionName];
  [fragaria setObject:@YES forKey:MGSFOIsSyntaxColoured];
  [fragaria setObject:@YES forKey:MGSFOShowLineNumberGutter];
  if (initialData) {
    [self loadData:initialData];
    initialData = nil;
  }
  
  textView = [fragaria objectForKey:ro_MGSFOTextView];
}


- (NSString *)windowNibName {
  return @"MOSSource";
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
  NSTextStorage *ts;
  NSRange allRange;
  NSDictionary *opts;
  NSData *res;
  NSNumber *enc;
  
  enc = [NSNumber numberWithInteger:NSUTF8StringEncoding];
  opts = @{NSDocumentTypeDocumentOption: NSPlainTextDocumentType,
           NSCharacterEncodingDocumentAttribute: enc};
  ts = [textView textStorage];
  
  allRange.length = [ts length];
  allRange.location = 0;
  res = [ts dataFromRange:allRange documentAttributes:opts error:outError];
  return res;
}


- (void)loadData:(NSData*)data {
  NSString *tmp;
  
  tmp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  [fragaria setString:tmp];
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
  if (fragaria)
    [self loadData:data];
  else
    initialData = data;
  return YES;
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
  if ([anItem action] == @selector(assembleAndRun:))
    return !assembler;
  if ([anItem action] == @selector(switchToEditor:))
    return simulatorMode && !assembler;
  if ([anItem action] == @selector(switchToSimulator:))
    return !simulatorMode && !assembler && assemblyOutput;
  return YES;
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
  
  if (simulatorMode) return;   /* already in simulator mode */
  if (assembler) return;       /* assembling */
  if (!assemblyOutput) return; /* never assembled */
  
  if (!simVc)
    simVc = [[MOSSimulatorViewController alloc]
      initWithNibName:@"MOSSimulatorView" bundle:[NSBundle mainBundle]];

  oldSimExec = [simVc simulatedExecutable];
  if (![oldSimExec isEqual:assemblyOutput]) {
    if (![simVc setSimulatedExecutable:assemblyOutput error:&err]) {
      [self presentError:err];
      simVc = nil;
      return;
    }
    
    if (oldSimExec) unlink([oldSimExec fileSystemRepresentation]);
  }
  simView = [simVc view];
  
  constr = [editView constraints];
  [editView removeConstraints:constr];
  
  contview = [[self windowForSheet] contentView];
  [contview setAnimations:@{@"subviews": [self transitionForViewSwitch]}];
  [[contview animator] replaceSubview:editView with:simView];
  [contview setAnimations:@{}];
  
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[simView]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(simView)]];
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[simView]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(simView)]];
  
  simulatorMode = YES;
}


- (IBAction)switchToEditor:(id)editor {
  NSView *contview;
  NSArray *constr;
  
  if (!simulatorMode) return;
  
  constr = [editView constraints];
  [simView removeConstraints:constr];
  
  contview = [[self windowForSheet] contentView];
  [contview setAnimations:@{@"subviews": [self transitionForViewSwitch]}];
  [[contview animator] replaceSubview:simView with:editView];
  [contview setAnimations:@{}];
  
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[editView]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(editView)]];
  [contview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[editView]|"
    options:0 metrics:nil views:NSDictionaryOfVariableBindings(editView)]];
  
  simulatorMode = NO;
}


- (IBAction)assembleAndRun:(id)sender {
  if (assembler) return;
  
  assemblyOutput = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
  assembler = [[MOSAssembler alloc] init];
  [assembler addObserver:self forKeyPath:@"complete" options:0 context:AssemblageComplete];
  
  [assembler setOutputFile:assemblyOutput];
  tempSourceCopy = [NSURL URLWithTemporaryFilePathWithExtension:@"s"];
  
  [self saveToURL:tempSourceCopy ofType:@"public.plain-text"
  forSaveOperation:NSSaveToOperation completionHandler:^(NSError *err){
    MOSJobStatusManager *jsm;
    NSDictionary *jobinfo;
    NSString *title;

    jsm = [MOSJobStatusManager sharedJobStatusManger];
    if ([self fileURL]) {
      title = [NSString stringWithFormat:@"Assemble %@", [[self fileURL] lastPathComponent]];
      jobinfo = @{MOSJobVisibleDescription: title,
                  MOSJobAssociatedFile: [self fileURL]};
    } else {
      title = [NSString stringWithFormat:@"Assemble %@", [[self windowForSheet] title]];
      jobinfo = @{MOSJobVisibleDescription: title};
    }
    lastJobId = [jsm addJobWithInfo:jobinfo];
    hadJob = YES;
    
    if (err) {
      [assembler removeObserver:self forKeyPath:@"complete" context:AssemblageComplete];
      assembler = nil;
      return;
    }
    [assembler setSourceFile:tempSourceCopy];
    [assembler setJobId:lastJobId];
    [assembler assemble];
  }];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context {
  MOSAssemblageResult asmres;
  NSArray *events;
  MOSJobStatusManager *sm;
  
  if (context == AssemblageComplete) {
    asmres = [assembler assemblageResult];
    [assembler removeObserver:self forKeyPath:@"complete" context:AssemblageComplete];
    assembler = nil;
    
    if (asmres != MOSAssemblageResultFailure) {
      unlink([tempSourceCopy fileSystemRepresentation]);
      [self switchToSimulator:self];
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


- (void)close {
  [simView removeFromSuperviewWithoutNeedingDisplay];
  simView = nil;
  simVc = nil;
}


- (void)dealloc {
  MOSJobStatusManager *sm;
  
  sm = [MOSJobStatusManager sharedJobStatusManger];
  [sm removeObserver:self forKeyPath:@"jobList" context:AssemblageEvent];
}


@end





