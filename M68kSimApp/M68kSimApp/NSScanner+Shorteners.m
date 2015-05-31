//
//  NSScanner+Shorteners.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 13/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
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


- (BOOL)scanCharactersFromString:(NSString *)set intoString:(NSString **)str {
  NSCharacterSet *cs;
  
  cs = [NSCharacterSet characterSetWithCharactersInString:set];
  return [self scanCharactersFromSet:cs intoString:str];
}


- (BOOL)scanUpToCharactersFromString:(NSString *)set intoString:(NSString **)str {
  NSCharacterSet *cs;
  
  cs = [NSCharacterSet characterSetWithCharactersInString:set];
  return [self scanUpToCharactersFromSet:cs intoString:str];
}


- (BOOL)scanCharactersFromString:(NSString *)set {
  return [self scanCharactersFromString:set intoString:nil];
}


- (BOOL)scanUpToCharactersFromString:(NSString *)set {
  return [self scanUpToCharactersFromString:set intoString:nil];
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
