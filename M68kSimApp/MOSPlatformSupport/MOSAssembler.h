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
@class MOSListingDictionary;


@protocol MOSAssemblerProtocol <NSObject>

@required

- (void)setJobStatus:(MOSJob *)js;
- (MOSJob *)jobStatus;

- (void)setSourceCode:(NSString*)sf;
- (NSString*)sourceCode;
- (void)setOutputFile:(NSURL*)of;
- (NSURL*)outputFile;
- (void)setAssemblageOptions:(MOSAssemblageOptions)opts;
- (MOSAssemblageOptions)assemblageOptions;

- (void)assemble;
- (BOOL)isAssembling;
- (BOOL)isComplete;
- (MOSAssemblageResult)assemblageResult;

@optional

- (BOOL)produceListingDictionary;
- (void)setProduceListingDictionary:(BOOL)ld;

- (MOSListingDictionary *)listingDictionary;

@end


@interface MOSAssembler : NSObject <MOSAssemblerProtocol> {
  MOSJob *jobStatus;
  NSURL *outputFile;
  MOSAssemblageOptions options;
}

/* run on main thread */
- (BOOL)prepareForAssembling;
/* run on background thread; to be implemented by a subclass */
- (MOSAssemblageResult)assembleThread;
/* run on main thread */
- (void)terminateAssemblingWithResult:(MOSAssemblageResult)res;

@end
