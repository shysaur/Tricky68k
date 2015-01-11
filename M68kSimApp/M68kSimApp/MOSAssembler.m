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


@implementation MOSAssembler


- (instancetype)init {
  self = [super init];

  running = NO;
  completed = NO;
  isJob = NO;
  
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
    NSArray *params2;
    
    task = [[MOSMonitoredTask alloc] init];
    execurl = [[NSBundle mainBundle] URLForAuxiliaryExecutable:@"vasmm68k-mot"];
    [task setLaunchURL:execurl];
    unlinkedelf = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
    params = [@[ @"-Felf", @"-spaces",
                @"-o", [unlinkedelf path], [sourceFile path]] mutableCopy];
    if (listingFile) {
      [params addObjectsFromArray:@[@"-L", [listingFile path]]];
    }
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
    params2 = @[@"--entry=0x2000", @"-o", [outputFile path], [unlinkedelf path], [linkerfile path]];
    [task setArguments:params2];
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
        [jsm finishJob:jobIdentifier withResult:MOSJobStatusSuccess];
      }
    });
  });
}


- (void)receivedTaskOutput:(NSString *)line {
  MOSJobStatusManager *jsm;
  
  if (!isJob)
    NSLog(@"taskoutput: %@", line);
  else {
    jsm = [MOSJobStatusManager sharedJobStatusManger];
    [jsm addEvent:@{MOSJobEventText: line} toJob:jobIdentifier];
  }
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
