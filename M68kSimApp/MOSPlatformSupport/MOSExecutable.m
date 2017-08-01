//
//  MOSAssemblerOutput.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/08/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import "MOSExecutable.h"


@implementation MOSExecutable


- (instancetype)initWithURL:(NSURL *)rep withError:(NSError **)errptr
{
  return [super init];
}


- (BOOL)writeToURL:(NSURL *)outf withError:(NSError **)errptr
{
  [NSException raise:NSGenericException format:@"MOSExecutable is an abstract class"];
  if (errptr)
    *errptr = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
  return NO;
}


@end
