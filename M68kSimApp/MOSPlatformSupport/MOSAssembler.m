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


@interface MOSAssembler ()

@property (nonatomic) NSString *sourceCode;

@property (atomic, getter=isAssembling) BOOL assembling;
@property (atomic, getter=isComplete) BOOL complete;
@property (nonatomic) MOSAssemblageResult assemblageResult;

@end


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


- (void)setSourceCode:(NSString *)sc {
  if ([self isAssembling] || [self isComplete])
    [NSException raise:NSInvalidArgumentException
                format: @"Can't change parameters after assembling."];
  _sourceCode = sc;
}


- (NSURL*)output {
  return nil;
}


- (void)setAssemblageOptions:(MOSAssemblageOptions)opts {
  options = opts;
}


- (MOSAssemblageOptions)assemblageOptions {
  return options;
}


- (void)assembleWithCompletionHandler:(void (^)(void))done {
  if (self.isAssembling || self.isComplete)
    [NSException raise:NSInvalidArgumentException
      format:@"Already assembled once."];
  if (![self sourceCode])
    [NSException raise:NSInvalidArgumentException
      format:@"Source code not specified"];
  
  [self setAssembling:YES];
  
  if (![self prepareForAssembling]) {
    [self terminateAssemblingWithResult:MOSAssemblageResultFailure];
    return;
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    MOSAssemblageResult res = [self assembleThread];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self terminateAssemblingWithResult:res];
      if (done)
        done();
    });
  });
}


- (BOOL)prepareForAssembling
{
  return YES;
}


- (MOSAssemblageResult)assembleThread
{
  NSLog(@"MOSAssembler is an abstract class; please implement -assembleThread "
         "in your subclass.");
  return MOSAssemblageResultFailure;
}


- (void)terminateAssemblingWithResult:(MOSAssemblageResult)res
{
  [self setAssemblageResult:res];
  [[self jobStatus] setStatus:MOSAsmResultToJobStat(res)];
  
  [self setComplete:YES];
  [self setAssembling:NO];
}


- (MOSAssemblageResult)assemblageResult {
  if (!self.isComplete)
    [NSException raise:NSInvalidArgumentException
                format:@"Assemblage is not complete yet."];
  return _assemblageResult;
}


@end
