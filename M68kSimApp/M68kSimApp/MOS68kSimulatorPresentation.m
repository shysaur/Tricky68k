//
//  MOS68kSimulatorPresentation.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 10/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOS68kSimulatorPresentation.h"
#import "MOS68kSimulator.h"


@implementation MOS68kSimulatorPresentation


- (instancetype)initWithSimulator:(MOS68kSimulator *)s {
  self = [super initWithSimulator:s];
  sim = s;
  return self;
}


@end
