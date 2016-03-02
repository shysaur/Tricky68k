//
//  NSFileHandle+Strings.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 30/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#include <fcntl.h>
#import "NSFileHandle+Strings.h"


@implementation NSFileHandle (Strings)


- (void)writeString:(NSString*)str {
  const char *bytes;
  NSData *data;
  
  bytes = [str UTF8String];
  data = [NSData dataWithBytes:bytes length:strlen(bytes)];
  [self writeData:data];
}


- (void)writeLine:(NSString*)str {
  NSString *temp;
  
  temp = [NSString stringWithFormat:@"%@\n", str];
  [self writeString:temp];
}


- (NSString*)readLine {
  int fildes;
  NSMutableString *str;
  NSError *readerr;
  char buf[128], *bufp;
  ssize_t res, c;
  
  fildes = [self fileDescriptor];
  str = [NSMutableString string];
  
  bufp = buf;
  c = 0;
  res = read(fildes, bufp, 1);
  while (res > 0 && *bufp != '\n') {
    c += res;
    bufp += res;
    if (c == 127) {
      *bufp = '\0';
      [str appendFormat:@"%s", buf];
      bufp = buf;
      c = 0;
    }
    do {
      res = read(fildes, bufp, 1);
    } while (res < 0 && (errno == EAGAIN || errno == EINTR));
  }
  if (res < 0 && errno != EAGAIN && errno != EINTR) {
    readerr = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
    [NSException raise:@"File handler error" format:@"%@", [readerr localizedDescription]];
  }

  if (bufp == buf && res == 0) return nil; /* eof */
  *bufp = '\0';
  [str appendFormat:@"%s", buf];
  return [str copy];
}


@end
