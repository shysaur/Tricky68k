//
//  NSURL+TemporaryFile.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 10/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "NSURL+TemporaryFile.h"


@implementation NSURL (TemporaryFile)


+ (instancetype)URLWithTemporaryFilePath {
  return [self URLWithTemporaryFilePathWithExtension:@"temp"];
}


+ (instancetype)URLWithTemporaryFilePathWithExtension:(NSString*)ext {
  NSFileManager *fm;
  NSString *uuid;
  NSString *bundleid;
  NSString *path;
  
  fm = [NSFileManager defaultManager];
  bundleid = [[NSBundle mainBundle] bundleIdentifier];
  do {
    uuid = [[NSUUID UUID] UUIDString];
    path = [NSString stringWithFormat:@"/tmp/temp.%@.%@.%@", bundleid, uuid, ext];
  } while ([fm fileExistsAtPath:path isDirectory:NO]);
  return [[NSURL alloc] initFileURLWithPath:path isDirectory:NO];
}


@end
