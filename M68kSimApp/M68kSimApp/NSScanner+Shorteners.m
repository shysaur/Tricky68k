//
//  NSScanner+Shorteners.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 13/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "NSScanner+Shorteners.h"


@implementation NSScanner (Shorteners)


- (BOOL)scanString:(NSString *)string {
  return [self scanString:string intoString:nil];
}


- (BOOL)scanUpToString:(NSString *)string {
  return [self scanUpToString:string intoString:nil];
}


- (BOOL)scanCharactersFromSet:(NSCharacterSet *)set {
  return [self scanCharactersFromSet:set intoString:nil];
}


- (BOOL)scanUpToCharactersFromSet:(NSCharacterSet *)set {
  return [self scanCharactersFromSet:set intoString:nil];
}


- (BOOL)scanCharactersFromString:(NSString *)set {
  NSCharacterSet *cs;
  
  cs = [NSCharacterSet characterSetWithCharactersInString:set];
  return [self scanCharactersFromSet:cs];
}


- (BOOL)scanUpToCharactersFromString:(NSString *)set{
  NSCharacterSet *cs;
  
  cs = [NSCharacterSet characterSetWithCharactersInString:set];
  return [self scanUpToCharactersFromSet:cs];
}


- (NSString *)scanUpToEndOfString {
  NSUInteger curidx;
  NSString *res;
  
  curidx = [self scanLocation];
  res = [[self string] substringFromIndex:curidx];
  [self setScanLocation:[[self string] length]];
  return res;
}



@end
