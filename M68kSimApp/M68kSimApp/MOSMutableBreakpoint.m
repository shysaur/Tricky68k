//
//  MOSMutableBreakpoint.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 04/10/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSMutableBreakpoint.h"
#import "MOSAddressFormatter.h"
#import "NSScanner+Shorteners.h"


static MOSAddressFormatter *addressFormatter;


@implementation MOSMutableBreakpoint


+ (void)initialize {
  if (self == [MOSMutableBreakpoint class]) {
    addressFormatter = [[MOSAddressFormatter alloc] init];
  }
}


- (instancetype)initWithAddress:(uint32_t)a {
  return [self initWithAddress:a symbolTable:@{} symbolLocator:@[]];
}


- (instancetype)initWithAddress:(uint32_t)a symbolTable:(NSDictionary*)st
                  symbolLocator:(NSArray*)l {
  self = [super init];
  _address = a;
  _symbolLocator = l;
  _symbolTable = st;
  return self;
}


- (NSNumber *)address {
  return @(_address);
}


- (void)setAddress:(NSNumber *)a {
  _address = [a unsignedIntValue];
  
  [self willChangeValueForKey:@"symbolicLocation"];
  _locationCache = nil;
  [self didChangeValueForKey:@"symbolicLocation"];
}


- (uint32_t)rawAddress {
  return _address;
}


- (NSString *)symbolicLocation {
  NSInteger i;
  NSNumber *n, *a;
  NSString *sym;
  uint32_t off;
  
  if (_locationCache)
    return _locationCache;
  
  a = [self address];
  i = [_symbolLocator indexOfObject:a
      inSortedRange:NSMakeRange(0, [_symbolLocator count])
      options: NSBinarySearchingInsertionIndex | NSBinarySearchingLastEqual
      usingComparator:^ NSComparisonResult(id obj1, id obj2) {
    return [obj1 compare:obj2];
  }];
  
  if (i == 0) {
    sym = @"0";
    off = [a unsignedIntValue];
  } else {
    if (i < [_symbolLocator count])
      n = [_symbolLocator objectAtIndex:i];
    if ([n isEqual:a]) {
      off = 0;
    } else {
      n = [_symbolLocator objectAtIndex:i-1];
      off = [a unsignedIntValue] - [n unsignedIntValue];
    }
    sym = [_symbolTable objectForKey:n];
  }
  
  if (off == 0)
    return _locationCache = sym;
  return _locationCache = [NSString stringWithFormat:@"%@ + 0x%X", sym, off];
}


- (void)setSymbolicLocation:(NSString *)str {
  NSNumber *a;
  
  if ((a = [self parseSymbolicLocation:str error:nil]))
    [self setAddress:a];
}


- (BOOL)validateSymbolicLocation:(id*)ioValue error:(NSError**)outError {
  return !![self parseSymbolicLocation:*ioValue error:outError];
}


- (NSNumber *)parseSymbolicLocation:(NSString*)str error:(NSError**)err {
  NSScanner *scan;
  
  scan = [NSScanner scannerWithString:str];
  return [self recursiveParseLocationWithScanner:scan insideParens:0 error:err];
}


- (NSNumber *)recursiveParseLocationWithScanner:(NSScanner*)scan
    insideParens:(BOOL)par error:(NSError**)err {
  id token;
  uint32_t lhside, rhside;
  unichar op;
  
  token = [self getTokenWithScanner:scan error:err];
  if (!token || ![token isKindOfClass:[NSNumber class]])
    return nil;
  lhside = [token unsignedIntValue];
  
  do {
    token = [self getTokenWithScanner:scan error:err];
    if (!token || ![token isKindOfClass:[NSString class]])
      return nil;
    if ([token isEqual:@""]) {
      if (!par)
        return @(lhside);
      return nil;
    }
    op = [token characterAtIndex:0];
    
    if (op == '*') {
      token = [self getTokenWithScanner:scan error:err];
      if (!token || ![token isKindOfClass:[NSNumber class]])
        return nil;
      rhside = [token unsignedIntValue];
      lhside *= rhside;
    }
  } while (op == '*');
  
  if (op == '+' || op == '-') {
    token = [self recursiveParseLocationWithScanner:scan insideParens:par error:err];
    if (!token || ![token isKindOfClass:[NSNumber class]])
      return nil;
    rhside = [token unsignedIntValue];
    if (op == '+')
      return @(lhside + rhside);
    return @(lhside - rhside);
  } else if (op == ')') {
    if (!par)
      return nil;
    return @(lhside);
  }
  
  return nil;
}


- (id)getTokenWithScanner:(NSScanner*)scan error:(NSError**)err {
  NSString *operator;
  NSString *token;
  NSNumber *value;
  NSArray *addrs;
  
  if ([scan scanAnyStringFromList:@[@"+", @"-", @"*", @")"] intoString:&operator])
    return operator;

  if ([scan scanString:@"("]) {
    return [self recursiveParseLocationWithScanner:scan insideParens:YES error:err];
  }
  
  if ([scan scanUpToCharactersFromString:@"+-*() \t" intoString:&token]) {
    if (![addressFormatter getObjectValue:&value forString:token errorDescription:nil]) {
      addrs = [_symbolTable allKeysForObject:token];
      if (![addrs count])
        return nil;
      value = [addrs firstObject];
    }
    return value;
  }
  
  if ([scan isAtEnd])
    return @"";
  return nil;
}


@end
