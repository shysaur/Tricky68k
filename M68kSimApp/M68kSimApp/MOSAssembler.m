//
//  MOSAssembler.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 09/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSAssembler.h"
#import "NSURL+TemporaryFile.h"
#import "MOSJobStatusManager.h"
#import "NSScanner+Shorteners.h"


NSString *MOSAsmResultToJobStat(MOSAssemblageResult ar) {
  switch (ar) {
    case MOSAssemblageResultSuccessWithWarning:
      return MOSJobStatusSuccessWithWarning;
    case MOSAssemblageResultSuccess:
      return MOSJobStatusSuccess;
    default: /* MOSAssemblageResultFailure */
      return MOSJobStatusFailure;
  }
  return nil;
}


@implementation MOSAssembler


- (instancetype)init {
  self = [super init];

  running = NO;
  completed = NO;
  isJob = NO;
  options = 0;
  
  return self;
}


- (void)setJobId:(NSUInteger)jobid {
  jobIdentifier = jobid;
  isJob = YES;
}


- (void)setSourceFile:(NSURL*)sf {
  if (running | completed)
    [NSException raise:NSInvalidArgumentException
      format: @"Can't change parameters after assembling."];
  if (![sf isFileURL])
    [NSException raise:NSInvalidArgumentException
      format:@"Assembler source file must be a local URL"];
  sourceFile = sf;
}


- (NSURL*)sourceFile {
  return sourceFile;
}


- (void)setOutputFile:(NSURL*)of {
  if (running | completed)
    [NSException raise:NSInvalidArgumentException
      format: @"Can't change parameters after assembling."];
  if (![of isFileURL])
    [NSException raise:NSInvalidArgumentException
      format:@"Assembler source file must be a local URL"];
  outputFile = of;
}


- (NSURL*)outputFile {
  return outputFile;
}


- (void)setOutputListingFile:(NSURL*)lf {
  if (running | completed)
    [NSException raise:NSInvalidArgumentException
      format: @"Can't change parameters after assembling."];
  if (![lf isFileURL])
    [NSException raise:NSInvalidArgumentException
      format:@"Assembler source file must be a local URL"];
  listingFile = lf;
}


- (NSURL*)outputListingFile {
  return listingFile;
}


- (void)setAssemblageOptions:(MOSAssemblageOptions)opts {
  options = opts;
}


- (MOSAssemblageOptions)assemblageOptions {
  return options;
}


- (void)assemble {
  if (running || completed)
    [NSException raise:NSInvalidArgumentException
      format:@"Already assembled once."];
  if (!sourceFile || !outputFile)
    [NSException raise:NSInvalidArgumentException
      format:@"Source file and output file not specified"];
  
  [self willChangeValueForKey:@"assembling"];
  running = YES;
  [self didChangeValueForKey:@"assembling"];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    MOSMonitoredTask *task;
    NSURL *execurl;
    NSURL *unlinkedelf;
    NSURL *linkerfile;
    NSMutableArray *params;
    
    task = [[MOSMonitoredTask alloc] init];
    execurl = [[NSBundle mainBundle] URLForAuxiliaryExecutable:@"vasmm68k-mot"];
    [task setLaunchURL:execurl];
    unlinkedelf = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
    
    params = [@[@"-quiet", @"-Felf", @"-spaces"] mutableCopy];
    if (!(options & MOSAssemblageOptionOptimizationOn))
      [params addObject:@"-no-opt"];
    [params addObjectsFromArray:@[@"-o", [unlinkedelf path], [sourceFile path]]];
    if (listingFile)
      [params addObjectsFromArray:@[@"-L", [listingFile path]]];
    
    [task setArguments:params];
    [task setDelegate:self];
    [task launch];
    [task waitUntilExit];
    if ([task terminationStatus] != 0) {
      asmResult = MOSAssemblageResultFailure;
      goto finish;
    }
    
    task = [[MOSMonitoredTask alloc] init];
    execurl = [[NSBundle mainBundle] URLForAuxiliaryExecutable:@"m68k-elf-ld"];
    [task setLaunchURL:execurl];
    linkerfile = [[NSBundle mainBundle] URLForResource:@"DefaultLinkerFile" withExtension:@"ld"];
    
    params = [NSMutableArray array];
    if (!(options & MOSAssemblageOptionEntryPointSymbolic))
      [params addObject:@"--entry=0x2000"];
    [params addObjectsFromArray:@[@"-o", [outputFile path]]];
    [params addObjectsFromArray:@[[unlinkedelf path], [linkerfile path]]];
    
    [task setArguments:params];
    [task setDelegate:self];
    [task launch];
    [task waitUntilExit];
    if ([task terminationStatus] != 0) {
      asmResult = MOSAssemblageResultFailure;
      goto finish;
    }
    
    asmResult = MOSAssemblageResultSuccess;
  finish:
    unlink([unlinkedelf fileSystemRepresentation]);
    dispatch_async(dispatch_get_main_queue(), ^{
      MOSJobStatusManager *jsm;
      
      [self willChangeValueForKey:@"complete"];
      completed = YES;
      [self didChangeValueForKey:@"complete"];
      [self willChangeValueForKey:@"assembling"];
      running = NO;
      [self didChangeValueForKey:@"assembling"];
      
      if (isJob) {
        jsm = [MOSJobStatusManager sharedJobStatusManger];
        [jsm finishJob:jobIdentifier withResult:MOSAsmResultToJobStat(asmResult)];
      }
    });
  });
}


- (void)receivedTaskOutput:(NSString *)line {
  MOSJobStatusManager *jsm;
  NSDictionary *event;

  if (!isJob)
    NSLog(@"taskoutput: %@", line);
  else {
    jsm = [MOSJobStatusManager sharedJobStatusManger];
    /* The parser is able to gracefully dismiss ld output as normal messages */
    event = [self parseVasmOutput:line];
    if (event) [jsm addEvent:event toJob:jobIdentifier];
  }
}


- (NSDictionary*)parseVasmOutput:(NSString *)line {
  NSMutableDictionary *res;
  NSScanner *scan;
  NSInteger lineno;
  BOOL isFatal;
  
  scan = [NSScanner scannerWithString:line];
  res = [NSMutableDictionary dictionary];
  
  /* No empty lines thanks */
  if ([line isEqual:@""]) return nil;
  
  /* Source code line echo: filter out */
  if ([scan scanString:@">"]) return nil;
  
  /* Pass nesting info lines as found */
  if ([scan scanString:@"called"] || [scan scanString:@"included"])
    goto returnAsIs;
  
  isFatal = [scan scanString:@"fatal"];
  if ([scan scanString:@"error"])
    [res setObject:MOSJobEventTypeError forKey:MOSJobEventType];
  else if ([scan scanString:@"message"])
    [res setObject:MOSJobEventTypeMessage forKey:MOSJobEventType];
  else if ([scan scanString:@"warning"])
    [res setObject:MOSJobEventTypeWarning forKey:MOSJobEventType];
  else {
    /* No error|message|warning header: something else we pass thru as is */
    goto returnAsIs;
  }
  /* skip eventual error number */
  [scan scanInteger:NULL];
  
  /* Check for line numbers */
  if ([scan scanString:@"in line"]) {
    if (![scan scanInteger:&lineno]) goto returnAsIs;
    [res setObject:[NSNumber numberWithInteger:lineno] forKey:MOSJobEventAssociatedLine];
    [scan scanUpToString:@"\": "];
    if (![scan scanString:@"\": "]) goto returnAsIs;
  } else {
    [scan scanUpToString:@": "];
    if (![scan scanString:@": "]) goto returnAsIs;
  }
  
  [res setObject:[scan scanUpToEndOfString] forKey:MOSJobEventText];
  if (isFatal) [res setObject:MOSJobEventTypeError forKey:MOSJobEventType];
  
  return [res copy];
  
returnAsIs:
  [res setObject:line forKey:MOSJobEventText];
  [res setObject:MOSJobEventTypeMessage forKey:MOSJobEventType];
  return [res copy];
}


- (BOOL)isAssembling {
  return running;
}


- (BOOL)isComplete {
  return completed;
}


- (MOSAssemblageResult)assemblageResult {
  if (!completed)
    [NSException raise:NSInvalidArgumentException
      format:@"Assemblage is not complete yet."];
  return asmResult;
}


@end
