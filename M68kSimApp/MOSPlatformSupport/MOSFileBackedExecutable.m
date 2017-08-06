//
//  MOSFileBackedExecutable.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/08/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import "MOSFileBackedExecutable.h"
#import "PlatformSupport.h"


@implementation MOSFileBackedExecutable


- (instancetype)initWithPersistentURL:(NSURL *)rep withError:(NSError **)errptr
{
  self = [super init];
  _executableFile = rep;
  MOSDbgLog(@"MOSFileBackedExecutable: acquired %@", rep);
  return self;
}


- (instancetype)initWithURL:(NSURL *)rep withError:(NSError **)errptr
{
  self = [super init];
  NSFileManager *fm = [NSFileManager defaultManager];
  _executableFile = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
  BOOL res = [fm copyItemAtURL:rep toURL:_executableFile error:errptr];
  if (res) {
    MOSDbgLog(@"MOSFileBackedExecutable: created %@ (from %@)", _executableFile, rep);
    return self;
  }
  return nil;
}


- (BOOL)writeToURL:(NSURL *)outf withError:(NSError **)errptr
{
  NSError *err;
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL res = [fm copyItemAtURL:self.executableFile toURL:outf error:&err];
  if (res)
    return YES;
  if (errptr)
    *errptr = err;
  return NO;
}


- (void)dealloc
{
  unlink([self.executableFile fileSystemRepresentation]);
  MOSDbgLog(@"MOSFileBackedExecutable: deleted %@", self.executableFile);
}


@end
