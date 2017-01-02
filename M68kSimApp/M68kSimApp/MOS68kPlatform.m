//
//  MOS68kPlatform.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 02/01/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import "MOS68kPlatform.h"
#import "MOS68kAssembler.h"
#import "MOS68kSimulator.h"
#import "MOS68kSimulatorPresentation.h"


@implementation MOS68kPlatform


- (Class)assemblerClass {
  return [MOS68kAssembler class];
}


- (Class)simulatorClass {
  return [MOS68kSimulator class];
}


- (Class)presentationClass {
  return [MOS68kSimulatorPresentation class];
}


- (NSString *)localizedName {
  return @"Motorola 68000";
}


@end
