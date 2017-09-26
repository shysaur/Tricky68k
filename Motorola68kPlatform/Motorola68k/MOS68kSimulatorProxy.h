//
//  MOSSimulatorProxy.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 12/06/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlatformSupport.h"


enum {
  MOSSimulatorErrorUnknown = -1,
  MOSSimulatorErrorTimeout = -2,
  MOSSimulatorErrorPipeOpeningFailure = -3,
  MOSSimulatorErrorUnrecognizedMessage = -4,
  MOSSimulatorErrorBrokenConnection = -5,
  MOSSimulatorErrorWrongState = -6
};


extern NSString * const MOSSimulatorErrorDomain;


@class MOSNamedPipe;


@interface MOS68kSimulatorProxy : NSObject {
  NSTask *simTask;
  NSURL *exec;
  NSError *_lastSimulationException;
  dispatch_semaphore_t waitingForDebugger;
  dispatch_semaphore_t enteredDebugger;
  dispatch_queue_t sendQueue;
  dispatch_queue_t receiveQueue;
  NSPipe *toSim;
  NSPipe *fromSim;
  MOSNamedPipe *toSimTty;
  MOSNamedPipe *fromSimTty;
  MOSSimulatorState curState;
}

- (instancetype)initWithExecutableURL:(NSURL*)url error:(NSError**)err;
- (NSURL*)executableURL;

- (MOSSimulatorState)simulatorState;

- (BOOL)enterDebuggerWithError:(NSError **)err;
- (BOOL)exitDebuggerWithCommand:(NSString*)com error:(NSError **)err;
- (NSArray*)sendCommandToDebugger:(NSString *)com error:(NSError **)err;
- (NSError*)lastSimulationException;

- (NSFileHandle*)teletypeOutput;
- (NSFileHandle*)teletypeInput;

- (void)kill;

@end
