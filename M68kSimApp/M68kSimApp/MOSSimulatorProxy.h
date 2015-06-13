//
//  MOSSimulatorProxy.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 12/06/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
  MOSSimulatorStateRunning,
  MOSSimulatorStatePaused,
  MOSSimulatorStateUnknown,
  MOSSimulatorStateDead
} MOSSimulatorState;


@class MOSNamedPipe;


@interface MOSSimulatorProxy : NSObject {
  NSTask *simTask;
  NSURL *exec;
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

- initWithExecutableURL:(NSURL*)url;
- (NSURL*)executableURL;

- (MOSSimulatorState)simulatorState;

- (void)enterDebugger;
- (void)exitDebuggerWithCommand:(NSString*)com;
- (NSArray*)sendCommandToDebugger:(NSString *)com;

- (NSFileHandle*)teletypeOutput;
- (NSFileHandle*)teletypeInput;

- (void)kill;

@end
