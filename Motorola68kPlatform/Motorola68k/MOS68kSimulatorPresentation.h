//
//  MOS68kSimulatorPresentation.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 10/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlatformSupport.h"


@class MOS68kSimulator;


@interface MOS68kSimulatorPresentation : MOSSimulatorPresentation {
  __weak MOS68kSimulator *sim;
  NSArray *regFileCache;
  NSDictionary *regsCache;
}

@end
