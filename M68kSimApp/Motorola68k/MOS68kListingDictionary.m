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
  NSUInteger lastLine, tmp, addr;
  NSNumber *line;
  NSMutableDictionary *l2a, *a2l;
  NSMutableArray *lastUnmatchedLines;
  
  self = [super init];
  
  fh = [NSFileHandle fileHandleForReadingFromURL:f error:e];
  if (!fh)
    return nil;
  
  l2a = [NSMutableDictionary dictionary];
  a2l = [NSMutableDictionary dictionary];
  lastUnmatchedLines = [NSMutableArray array];
  
  l = [fh readLine];
  lastLine = addr = NSNotFound;
  while ([l length] > 0) {
    lp = [l UTF8String];
    
    if (lp[0] == 'F') {
      /* Each source line is preceded by Fxx:yyyy where xx is a sequential
       * number that identifies the file, and yyyy is the line number. */
      if ([l length] < 8)
        goto parseFail;
      
      /* Get the line number. Ignore the file number (it is always 1 in our 
       * case */
      if (sscanf(lp+4, "%ld", &tmp) < 1)
        goto parseFail;
      if (lastLine == NSNotFound)
        firstSeenLine = tmp;
      lastLine = tmp;
      [lastUnmatchedLines addObject:@(lastLine)];
      
      addr = NSNotFound;
      
    } else if (lp[0] == ' ') {
      /* If a source line maps to some data in the output, it is followed
       * by a data line, made of 16 spaces, followed by Sxx:yyyyyyyy where
       * xx is a section number and yyyyyyyy is the starting address of the
       * data. */
      if (lastLine == NSNotFound || [l length] < 28)
        goto parseFail;
      if (lp[15] != 'S')
        goto parseFail;
      
      /* A source line may be followed by more than one data line. Ignore
       * all data lines except the first. */
      if (addr == NSNotFound) {
        /* Get the address. Ignore the section number. */
        if (sscanf(lp+19, "%lX", &addr) < 1)
          goto parseFail;
        
        /* Map all preceding lines to this address. */
        for (line in lastUnmatchedLines)
          [l2a setObject:@(addr) forKey:line];
        [lastUnmatchedLines removeAllObjects];
        
        /* Map only this address to the last source line. */
        [a2l setObject:@(lastLine) forKey:@(addr)];
        lastSeenLine = lastLine;
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
  if (l < firstSeenLine)
    return [lineToAddress objectForKey:@(firstSeenLine)];
  if (l > lastSeenLine)
    return [lineToAddress objectForKey:@(lastSeenLine)];
  return [lineToAddress objectForKey:@(l)];
}


- (NSUInteger)sourceLineForAddress:(NSNumber *)n {
  return [[addressToLine objectForKey:n] integerValue];
}


@end
