//
//  MOSSimulator.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 10/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
  MOSSimulatorStateRunning,
  MOSSimulatorStatePaused,
  MOSSimulatorStateUnknown,
  MOSSimulatorStateDead
} MOSSimulatorState;


@protocol MOSSimulatorProtocol <NSObject>

@required

- initWithExecutableURL:(NSURL*)url error:(NSError **)err;
- (NSURL*)executableURL;

- (BOOL)run;
- (BOOL)stop;
- (BOOL)stepIn;
- (BOOL)stepOver;
- (void)kill;

- (NSError *)lastSimulatorException;
- (MOSSimulatorState)simulatorState;
- (BOOL)isSimulatorRunning;
- (BOOL)isSimulatorDead;

- (NSArray*)disassemble:(int)cnt instructionsFromLocation:(uint32_t)loc;
- (NSArray*)dump:(int)cnt linesFromLocation:(uint32_t)loc;
- (NSData*)rawDumpFromLocation:(uint32_t)loc withSize:(uint32_t)size;
- (NSDictionary*)registerDump;

- (float)clockFrequency;
- (void)setMaximumClockFrequency:(double)mhz;

- (NSSet*)breakpointList;
- (void)addBreakpoints:(NSSet*)addrs;
- (void)removeAllBreakpoints;
- (void)addBreakpointAtAddress:(uint32_t)addr;
- (void)removeBreakpointAtAddress:(uint32_t)addr;

- (NSDictionary *)symbolTable;

- (void)setSendToTeletypeBlock:(void (^)(NSString *string))block;
- (void)sendToSimulator:(NSString*)string;

@end


@interface MOSSimulator : NSObject <MOSSimulatorProtocol>

@end
