//
//  MOSAssembler.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 07/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


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


NSString *MOSAsmResultToJobStat(MOSAssemblageResult ar);


@class MOSJob;


@interface MOSAssembler : NSObject {
  MOSJob *jobStatus;
  NSURL *sourceFile;
  NSURL *outputFile;
  NSURL *listingFile;
  MOSAssemblageOptions options;
}

- (void)setJobStatus:(MOSJob *)js;
- (MOSJob *)jobStatus;

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
