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
    [serror setLine:[[event objectForKey:MOSJobEventAssociatedLine] intValue]];
    [serrors addObject:serror];
  }
  return [serrors copy];
}


@implementation MOSSource


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  MOSJobStatusManager *sm;
  
  [super windowControllerDidLoadNib:aController];
  
  hadJob = NO;
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
  if ([anItem action] == @selector(assembleAndRun:)) return !assembler;
  return YES;
}


- (IBAction)assembleAndRun:(id)sender {
  if (assembler) return;
  
  assemblyOutput = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
  @try {
    [assembler removeObserver:self forKeyPath:@"complete" context:AssemblageComplete];
  } @finally {}
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
    title = [NSString stringWithFormat:@"Assemble %@", [[self fileURL] lastPathComponent]];
    jobinfo = @{MOSJobVisibleDescription: title,
                MOSJobAssociatedFile: [self fileURL]};
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
  NSArray *events;
  MOSJobStatusManager *sm;
  
  if (context == AssemblageComplete) {
    NSLog(@"Assemblage has finished");
    if ([assembler assemblageResult] == MOSAssemblageResultFailure) {
      NSLog(@"Assemblage failed");
    } else {
      unlink([tempSourceCopy fileSystemRepresentation]);
      [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:assemblyOutput display:YES completionHandler:nil];
    }
    
    [assembler removeObserver:self forKeyPath:@"complete" context:AssemblageComplete];
    assembler = nil;
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


- (void)dealloc {
  MOSJobStatusManager *sm;
  
  sm = [MOSJobStatusManager sharedJobStatusManger];
  [sm removeObserver:self forKeyPath:@"jobList" context:AssemblageEvent];
}


@end





