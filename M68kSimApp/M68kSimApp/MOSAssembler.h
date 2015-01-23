//
//  MOSAssembler.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 09/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOSMonitoredTask.h"


typedef enum {
  MOSAssemblageResultSuccess,
  MOSAssemblageResultFailure,
  MOSAssemblageResultSuccessWithWarning,
} MOSAssemblageResult;

typedef NS_OPTIONS(NSUInteger, MOSAssemblageOptions) {
  MOSAssemblageOptionOptimizationOff = 0,
  MOSAssemblageOptionOptimizationOn = 1 << 0,
  MOSAssemblageOptionEntryPointFixed = 0,
  MOSAssemblageOptionEntryPointSymbolic = 1 << 1,
};


@interface MOSAssembler : NSObject <MOSMonitoredTaskDelegate> {
  NSUInteger jobIdentifier;
  BOOL isJob;
  NSURL *sourceFile;
  NSURL *outputFile;
  NSURL *listingFile;
  MOSAssemblageResult asmResult;
  MOSAssemblageOptions options;
  BOOL running;
  BOOL completed;
}

- (void)setJobId:(NSUInteger)jobid;

- (void)setSourceFile:(NSURL*)sf;
- (NSURL*)sourceFile;
- (void)setOutputFile:(NSURL*)of;
- (NSURL*)outputFile;
- (void)setOutputListingFile:(NSURL*)lf;
- (NSURL*)outputListingFile;
- (void)setAssemblageOptions:(MOSAssemblageOptions)opts;
- (MOSAssemblageOptions)assemblageOptions;

- (void)assemble;
- (BOOL)isAssembling;
- (BOOL)isComplete;
- (MOSAssemblageResult)assemblageResult;

@end
