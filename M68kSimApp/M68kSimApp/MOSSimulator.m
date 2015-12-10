//
//  MOSSimulator.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 10/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulator.h"


#define SUBCLASS_MUST_IMPLEMENT(x) { \
  [NSException raise:NSGenericException format:@"You should implement this"]; \
  return x; \
}


@implementation MOSSimulator


- initWithExecutableURL:(NSURL*)url error:(NSError **)err
  SUBCLASS_MUST_IMPLEMENT(nil);
- (NSURL*)executableURL
  SUBCLASS_MUST_IMPLEMENT(nil);

- (BOOL)run SUBCLASS_MUST_IMPLEMENT(NO);
- (BOOL)stop SUBCLASS_MUST_IMPLEMENT(NO);
- (BOOL)stepIn SUBCLASS_MUST_IMPLEMENT(NO);
- (BOOL)stepOver SUBCLASS_MUST_IMPLEMENT(NO);
- (void)kill SUBCLASS_MUST_IMPLEMENT();

- (NSError *)lastSimulatorException SUBCLASS_MUST_IMPLEMENT(nil);
- (MOSSimulatorState)simulatorState SUBCLASS_MUST_IMPLEMENT(0);
- (BOOL)isSimulatorRunning SUBCLASS_MUST_IMPLEMENT(NO);
- (BOOL)isSimulatorDead SUBCLASS_MUST_IMPLEMENT(NO);

- (NSArray*)disassemble:(int)cnt instructionsFromLocation:(uint32_t)loc
  SUBCLASS_MUST_IMPLEMENT(nil);
- (NSArray*)dump:(int)cnt linesFromLocation:(uint32_t)loc
  SUBCLASS_MUST_IMPLEMENT(nil);
- (NSData*)rawDumpFromLocation:(uint32_t)loc withSize:(uint32_t)size
  SUBCLASS_MUST_IMPLEMENT(nil);
- (NSDictionary*)registerDump
  SUBCLASS_MUST_IMPLEMENT(nil);

- (float)clockFrequency SUBCLASS_MUST_IMPLEMENT(0);
- (void)setMaximumClockFrequency:(double)mhz SUBCLASS_MUST_IMPLEMENT();

- (NSSet*)breakpointList SUBCLASS_MUST_IMPLEMENT(nil);
- (void)addBreakpoints:(NSSet*)addrs SUBCLASS_MUST_IMPLEMENT();
- (void)removeAllBreakpoints SUBCLASS_MUST_IMPLEMENT();
- (void)addBreakpointAtAddress:(uint32_t)addr SUBCLASS_MUST_IMPLEMENT();
- (void)removeBreakpointAtAddress:(uint32_t)addr SUBCLASS_MUST_IMPLEMENT();

- (NSDictionary *)symbolTable SUBCLASS_MUST_IMPLEMENT(nil);

- (void)setSendToTeletypeBlock:(void (^)(NSString *string))block
  SUBCLASS_MUST_IMPLEMENT();
- (void)sendToSimulator:(NSString*)string
  SUBCLASS_MUST_IMPLEMENT();


@end
