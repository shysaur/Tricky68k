//
//  MOSPlatformManager.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 02/01/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import "MOSPlatformManager.h"
#import "MOSPlatform.h"


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
  NSBundle *mb;
  NSDirectoryEnumerator *de;
  NSURL *pluginurl;
  NSBundle *plugin;
  
  platforms = [[NSMutableArray alloc] init];
  
  mb = [NSBundle mainBundle];
  
  de = [[NSFileManager defaultManager] enumeratorAtURL:[mb builtInPlugInsURL] includingPropertiesForKeys:nil options:0 errorHandler:nil];
  while (pluginurl = [de nextObject]) {
    if (![[pluginurl pathExtension] isEqual:@"mosplatform"])
      continue;
    plugin = [NSBundle bundleWithURL:pluginurl];
    [plugin load];
    [platforms addObject:[[[plugin principalClass] alloc] init]];
  }
  return YES;
}


- (MOSPlatform *)defaultPlatform {
  return [platforms firstObject];
}


@end
