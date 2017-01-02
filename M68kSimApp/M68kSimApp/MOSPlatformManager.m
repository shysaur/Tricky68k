//
//  MOSPlatformManager.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 02/01/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import "MOSPlatformManager.h"
#import "MOSPlatform.h"
#import "MOS68kPlatform.h"


@implementation MOSPlatformManager


+ (MOSPlatformManager *)sharedManager {
  static MOSPlatformManager *pm;
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    pm = [[MOSPlatformManager alloc] init];
  });
  return pm;
}


- (BOOL)loadPlatformsWithError:(NSError **)err {
  platforms = @[[[MOS68kPlatform alloc] init]];
  return YES;
}


- (MOSPlatform *)defaultPlatform {
  return [platforms firstObject];
}


@end
