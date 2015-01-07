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


@implementation MOSNamedPipe


- init {
  char temp[80] = "/tmp/tempMOSNamedPipe.XXXXXXXXXXXXXXXX";
  
  self = [super init];
  
  if (!mktemp(temp)) return nil;
  if (mkfifo(temp, 0666)) return nil;
  
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
  unlink([[mount path] UTF8String]);
}


@end
