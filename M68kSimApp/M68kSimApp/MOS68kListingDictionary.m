//
//  MOS68kListingDictionary.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 04/03/16.
//  Copyright © 2016 Daniele Cattaneo. All rights reserved.
//

#import "MOS68kListingDictionary.h"
#import "NSFileHandle+Strings.h"
#import "MOSError.h"


NSString * const MOSListingErrorDomain = @"MOSListingErrorDomain";


@implementation MOS68kListingDictionary


- (instancetype)initWithListingFile:(NSURL *)f error:(NSError **)e {
  NSFileHandle *fh;
  NSString *l;
  const char *lp;
  NSUInteger lastLine, addr;
  NSMutableDictionary *l2a, *a2l;
  
  self = [super init];
  
  fh = [NSFileHandle fileHandleForReadingFromURL:f error:e];
  if (!fh)
    return nil;
  
  l2a = [NSMutableDictionary dictionary];
  a2l = [NSMutableDictionary dictionary];
  
  l = [fh readLine];
  lastLine = addr = NSNotFound;
  while ([l length] > 0) {
    lp = [l UTF8String];
    
    if (lp[0] == 'F') {
      if ([l length] < 8)
        goto parseFail;
      if (sscanf(lp+4, "%ld", &lastLine) < 1)
        goto parseFail;
      addr = NSNotFound;
    } else if (lp[0] == ' ') {
      if (lastLine == NSNotFound || [l length] < 28)
        goto parseFail;
      if (lp[15] != 'S')
        goto parseFail;
      if (addr == NSNotFound) {
        if (sscanf(lp+19, "%lX", &addr) < 1)
          goto parseFail;
        [l2a setObject:@(addr) forKey:@(lastLine)];
        [a2l setObject:@(lastLine) forKey:@(addr)];
      }
    } else
      goto parseFail;
    
    l = [fh readLine];
  }
  
  addressToLine = a2l;
  lineToAddress = l2a;
  
  return self;
parseFail:
  if (e)
    *e = [MOSError errorWithDomain:MOSListingErrorDomain code:0 userInfo:nil];
  return nil;
}


- (NSNumber *)addressForSourceLine:(NSUInteger)l {
  return [lineToAddress objectForKey:@(l)];
}


- (NSUInteger)sourceLineForAddress:(NSNumber *)n {
  return [[addressToLine objectForKey:n] integerValue];
}


@end
