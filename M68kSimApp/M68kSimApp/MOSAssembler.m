//
//  MOSAssembler.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 07/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSAssembler.h"
#import "MOSJob.h"


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
  options = 0;
  return self;
}


- (void)setJobStatus:(MOSJob *)js {
  jobStatus = js;
}


- (MOSJob *)jobStatus {
  return jobStatus;
}


- (void)setSourceFile:(NSURL*)sf {
  if ([self isAssembling] | [self isComplete])
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
  if ([self isAssembling] | [self isComplete])
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
  if ([self isAssembling] | [self isComplete])
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
  [NSException raise:NSGenericException format:@"MOSAssembler is an abstract "
    "class; please implement -assemble in your subclass."];
}


- (BOOL)isAssembling {
  return NO;
}


- (BOOL)isComplete {
  return NO;
}


- (MOSAssemblageResult)assemblageResult {
  [NSException raise:NSInvalidArgumentException
              format:@"Assemblage is not complete yet."];
  return MOSAssemblageResultFailure;
}


@end
