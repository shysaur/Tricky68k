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

typedef NSInteger MOSAssemblageOptions;
enum {
  MOSAssemblageOptionFirstPlatformSpecificOption = 1 << 16
};


NSString *MOSAsmResultToJobStat(MOSAssemblageResult ar);


@class MOSJob;
@class MOSListingDictionary;
@class MOSExecutable;


@protocol MOSAssemblerProtocol <NSObject>

@required

- (void)setJobStatus:(MOSJob *)js;
- (MOSJob *)jobStatus;

- (void)setSourceCode:(NSString*)sf;
- (NSString*)sourceCode;
- (MOSExecutable*)output;
- (void)setAssemblageOptions:(MOSAssemblageOptions)opts;
- (MOSAssemblageOptions)assemblageOptions;

- (void)assembleWithCompletionHandler:(void (^)(void))done;
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
  MOSAssemblageOptions options;
}

/* run on main thread */
- (BOOL)prepareForAssembling;
/* run on background thread; to be implemented by a subclass */
- (MOSAssemblageResult)assembleThread;
/* run on main thread */
- (void)terminateAssemblingWithResult:(MOSAssemblageResult)res;

@end
