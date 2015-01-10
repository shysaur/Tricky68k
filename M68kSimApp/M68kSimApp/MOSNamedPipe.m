//
//  MOSNamedPipe.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#import "MOSNamedPipe.h"
#import "NSURL+TemporaryFile.h"


@implementation MOSNamedPipe


- init {
  int res;
  const char *temp;
  NSURL *tempUrl;
  
  self = [super init];
  
  do {
    tempUrl = [NSURL URLWithTemporaryFilePath];
    temp = [tempUrl fileSystemRepresentation];
    res = mkfifo(temp, 0666);
    if (res < 0 && errno != EEXIST) return nil;
  } while (res < 0);
  
  mount = [[NSURL alloc] initFileURLWithFileSystemRepresentation:temp
    isDirectory:NO relativeToURL:nil];
  return self;
}


+ pipe {
  return [[self alloc] init];
}


- (NSURL*)pipeURL {
  return mount;
}


- (NSFileHandle *)fileHandleForReading {
  if (writeFh) return nil;
  if (readFh) return readFh;
  readFh = [NSFileHandle fileHandleForReadingFromURL:mount error:nil];
  return readFh;
}


- (NSFileHandle *)fileHandleForWriting {
  if (readFh) return nil;
  if (writeFh) return writeFh;
  writeFh = [NSFileHandle fileHandleForWritingToURL:mount error:nil];
  return writeFh;
}


- (void)dealloc {
  if (writeFh) [writeFh closeFile];
  if (readFh) [readFh closeFile];
  unlink([[mount path] fileSystemRepresentation]);
}


@end
