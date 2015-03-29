//
//  MOSAssembler.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 09/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSAssembler.h"
#import "NSURL+TemporaryFile.h"
#import "NSFileHandle+Strings.h"
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
  
  gotWarnings = NO;
  sections = [NSMutableArray array];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    MOSMonitoredTask *task;
    NSURL *execurl;
    NSURL *unlinkedelf;
    NSURL *linkerfile;
    NSMutableArray *params;
    MOSJobStatusManager *jsm;
    
    jsm = [MOSJobStatusManager sharedJobStatusManger];
    
    linking = NO;
    task = [[MOSMonitoredTask alloc] init];
    execurl = [[NSBundle mainBundle] URLForAuxiliaryExecutable:@"vasmm68k-mot"];
    [task setLaunchURL:execurl];
    unlinkedelf = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
    
    params = [@[@"-Felf", @"-spaces"] mutableCopy];
    if (!(options & MOSAssemblageOptionOptimizationOn))
      [params addObject:@"-no-opt"];
    [params addObjectsFromArray:@[@"-o", [unlinkedelf path], [sourceFile path]]];
    if (listingFile)
      [params addObjectsFromArray:@[@"-L", [listingFile path]]];
    
    [task setArguments:params];
    [task setDelegate:self];
    [task launch];
    [task waitUntilExit];
    if ([task terminationStatus] != 0) goto fail;
    
    linking = YES;
    task = [[MOSMonitoredTask alloc] init];
    execurl = [[NSBundle mainBundle] URLForAuxiliaryExecutable:@"m68k-elf-ld"];
    [task setLaunchURL:execurl];
    linkerfile = [NSURL URLWithTemporaryFilePathWithExtension:@"ld"];
    if (![self makeLinkerFile:linkerfile]) {
      [jsm addEvent:@{
        MOSJobEventType: MOSJobEventTypeError,
        MOSJobEventText: NSLocalizedString(@"Could not create a linker file.",
          @"Text of the event which occurs when creating a linker file failed.")
        } toJob:jobIdentifier];
      goto fail;
    }
    
    params = [NSMutableArray array];
    if (!(options & MOSAssemblageOptionEntryPointSymbolic))
      [params addObject:@"--entry=0x2000"];
    else
      [params addObject:@"--entry=start"];
    [params addObjectsFromArray:@[@"-o", [outputFile path], @"-T", [linkerfile path]]];
    [params addObjectsFromArray:@[[unlinkedelf path]]];
    
    [task setArguments:params];
    [task setDelegate:self];
    [task launch];
    [task waitUntilExit];
    if ([task terminationStatus] != 0) goto fail;
    
    if (gotWarnings)
      asmResult = MOSAssemblageResultSuccessWithWarning;
    else
      asmResult = MOSAssemblageResultSuccess;
    goto finish;
  fail:
    asmResult = MOSAssemblageResultFailure;
  finish:
    unlink([unlinkedelf fileSystemRepresentation]);
    unlink([linkerfile fileSystemRepresentation]);
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


- (BOOL)makeLinkerFile:(NSURL*)ld {
  int fh;
  const char *sns;
  uint32_t segment_addr;
  NSString *section;
  NSFileHandle *nfh;
  BOOL isAbsolute, res;
  
  fh = open([ld fileSystemRepresentation], O_WRONLY | O_CREAT, 0666);
  if (fh < 0) return NO;
  nfh = [[NSFileHandle alloc] initWithFileDescriptor:fh closeOnDealloc:YES];
  if (!nfh) return NO;
  
  res = YES;
  @try {
    [nfh writeString:
     @"MEMORY {\n"
      "  vectors(rw) : ORIGIN = 0x00000000, LENGTH = 0x00000400\n"
      "  ram(rwx)    : ORIGIN = 0x00000400, LENGTH = 0x01000000\n"
      "}\n"];
    
    [nfh writeLine:@"SECTIONS {"];
    for (section in sections) {
      [nfh writeString:section];
      [nfh writeString:@" "];
      sns = [section UTF8String];
      if (strstr(sns, "seg") == sns) {
        isAbsolute = YES;
        sscanf(sns+3, "%x", &segment_addr);
        [nfh writeString:[NSString stringWithFormat:@"0x%X ", segment_addr]];
      } else
        isAbsolute = NO;
      [nfh writeString:@": { *("];
      [nfh writeString:section];
      [nfh writeString:@") }"];
      if (!isAbsolute)
        [nfh writeLine:@" > ram"];
      else
        [nfh writeLine:@""];
    }
    [nfh writeLine:@"}"];
  } @catch (NSException *exc) {
    res = NO;
  }
  
  [nfh closeFile];
  return res;
}


- (void)receivedTaskOutput:(NSString *)line {
  MOSJobStatusManager *jsm;
  NSDictionary *event;

  if (!isJob)
    NSLog(@"taskoutput: %@", line);
  else {
    jsm = [MOSJobStatusManager sharedJobStatusManger];
    if (!linking)
      event = [self parseVasmOutput:line];
    else
      event = [self parseLinkerOutput:line];
    if (event) [jsm addEvent:event toJob:jobIdentifier];
  }
}


- (NSDictionary*)parseVasmOutput:(NSString *)line {
  NSMutableDictionary *res;
  NSScanner *scan;
  NSInteger lineno;
  NSString *secname;
  BOOL isFatal;
  
  scan = [NSScanner scannerWithString:line];
  res = [NSMutableDictionary dictionary];
  
  /* No empty lines thanks */
  if ([line isEqual:@""]) return nil;
  /* Filter out the banner */
  if ([scan scanString:@"vasm "]) return nil;
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
  else if ([scan scanString:@"warning"]) {
    [res setObject:MOSJobEventTypeWarning forKey:MOSJobEventType];
    gotWarnings = YES;
  } else {
    /* No error|message|warning header: might be a section name */
    /* Section name is terminated by an open parens */
    if (![scan scanUpToString:@"(" intoString:&secname]) goto returnAsIs;
    /* The line must end by the "bytes" string */
    [scan scanUpToString:@"bytes"];
    if (![scan scanString:@"bytes"]) goto returnAsIs;
    /* If both of these conditions are fulfilled, add a section to the array */
    [sections addObject:secname];
    return nil;
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


- (NSDictionary*)parseLinkerOutput:(NSString *)line {
  NSMutableDictionary *res;
  NSScanner *scan;
  
  scan = [NSScanner scannerWithString:line];
  res = [NSMutableDictionary dictionary];
  
  /* Skip the filename */
  [scan scanUpToString:@":"];
  if (![scan scanString:@":"]) goto returnAsIs;
  
  if ([scan scanString:@"warning: "]) {
    gotWarnings = YES;
    [res setObject:MOSJobEventTypeWarning forKey:MOSJobEventType];
  } else
    [res setObject:MOSJobEventTypeError forKey:MOSJobEventType];
  
  /* Return the rest of the line as a message */
  [res setObject:[scan scanUpToEndOfString] forKey:MOSJobEventText];
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
