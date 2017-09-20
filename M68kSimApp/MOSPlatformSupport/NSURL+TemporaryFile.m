//
//  NSURL+TemporaryFile.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 10/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "NSURL+TemporaryFile.h"


@implementation NSURL (TemporaryFile)


+ (instancetype)URLWithTemporaryFilePath {
  return [self URLWithTemporaryFilePathWithExtension:@"temp"];
}


+ (instancetype)URLWithTemporaryFilePathWithExtension:(NSString*)ext {
  NSFileManager *fm;
  NSString *tempdir;
  NSString *uuid;
  NSString *bundleid;
  NSString *path;
  
  fm = [NSFileManager defaultManager];
  bundleid = [[NSBundle mainBundle] bundleIdentifier];
  tempdir = NSTemporaryDirectory();
  do {
    uuid = [[NSUUID UUID] UUIDString];
    path = [NSString stringWithFormat:@"%@/%@.%@.%@", tempdir, bundleid, uuid, ext];
  } while ([fm fileExistsAtPath:path isDirectory:nil]);
  return [[NSURL alloc] initFileURLWithPath:path isDirectory:NO];
}


@end
