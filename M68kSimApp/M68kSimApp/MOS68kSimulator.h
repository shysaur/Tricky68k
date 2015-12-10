//
//  MOSSimulatorProxy.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import <Foundation/Foundation.h>
#import "MOSSimulator.h"


extern NSString * const MOS68kRegisterD0;
extern NSString * const MOS68kRegisterD1;
extern NSString * const MOS68kRegisterD2;
extern NSString * const MOS68kRegisterD3;
extern NSString * const MOS68kRegisterD4;
extern NSString * const MOS68kRegisterD5;
extern NSString * const MOS68kRegisterD6;
extern NSString * const MOS68kRegisterD7;
extern NSString * const MOS68kRegisterA0;
extern NSString * const MOS68kRegisterA1;
extern NSString * const MOS68kRegisterA2;
extern NSString * const MOS68kRegisterA3;
extern NSString * const MOS68kRegisterA4;
extern NSString * const MOS68kRegisterA5;
extern NSString * const MOS68kRegisterA6;
extern NSString * const MOS68kRegisterSP;
extern NSString * const MOS68kRegisterPC;
extern NSString * const MOS68kRegisterSR;
extern NSString * const MOS68kRegisterUSP;
extern NSString * const MOS68kRegisterISP;
extern NSString * const MOS68kRegisterMSP;
extern NSString * const MOS68kRegisterSFC;
extern NSString * const MOS68kRegisterDFC;
extern NSString * const MOS68kRegisterVBR;
extern NSString * const MOS68kRegisterCACR;
extern NSString * const MOS68kRegisterCAAR;


@class MOS68kSimulatorProxy;


@interface MOS68kSimulator : MOSSimulator {
  NSError *lastError;
  MOSSimulatorState stateMirror;
  MOS68kSimulatorProxy *proxy;
  void (^ttySendBlock)(NSString *string);
  NSDictionary *regsCache;
  NSDictionary *symbolsCache;
  BOOL isSimDead;
  BOOL disableNotifications;
  MOSSimulatorPresentation *pres;
}


@end
