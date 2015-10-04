//
//  MOSAddressFormatter.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 03/10/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSAddressFormatter.h"


@implementation MOSAddressFormatter


- (NSString *)stringForObjectValue:(id)obj {
  if (![obj isKindOfClass:[NSNumber class]])
    return @"0";
  return [NSString stringWithFormat:@"0x%08X", [obj unsignedIntValue]];
}


- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string
      errorDescription:(NSString **)error {
  const char *cs;
  char *end;
  unsigned long res;
  
  cs = [string UTF8String];
  if (!cs)
    goto fail;
  
  res = strtoul(cs, &end, 0);
  while (*end) {
    if (!isblank(*(end++)))
      goto fail;
  }
  if (res > UINT32_MAX)
    goto fail;
  
  if (obj)
    *obj = @(res);
  return YES;
                                          
fail:
  if (error) *error = NSLocalizedString(@"Not a valid memory address!",
    @"Error description when MOSAddressFormatter fails.");
  return NO;
}


@end
