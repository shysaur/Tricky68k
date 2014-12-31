//
//  MOSSimulatorProxy.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
  MOSSimulatorStateRunning,
  MOSSimulatorStatePaused,
  MOSSimulatorStateUnknown,
  MOSSimulatorStateDead
} MOSSimulatorState;


@interface MOSSimulatorProxy : NSObject {
  dispatch_queue_t simQueue;
  NSTask *simTask;
  NSURL *exec;
  NSPipe *toSim;
  NSPipe *fromSim;
  MOSSimulatorState curState;
  BOOL isSimDead;
}


- initWithExecutableURL:(NSURL*)url;

- (BOOL)run;
- (BOOL)stop;
- (BOOL)stepIn;
- (BOOL)stepOver;
- (void)kill;

- (MOSSimulatorState)simulatorState;
- (BOOL)isSimulatorRunning;
- (BOOL)isSimulatorDead;

- (NSArray*)disassemble:(int)cnt instructionsFromLocation:(uint32_t)loc;
- (NSArray*)dump:(int)cnt linesFromLocation:(uint32_t)loc;


@end
