//
//  MOSListingDictionary.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 04/03/16.
//  Copyright © 2016 Daniele Cattaneo. All rights reserved.
//

#import "MOSListingDictionary.h"


@implementation MOSListingDictionary


- (instancetype)initWithListingFile:(NSURL *)f error:(NSError **)e {
  self = [super init];
  return self;
}


- (NSNumber *)addressForSourceLine:(NSUInteger)l {
  [NSException raise:NSGenericException format:@"MOSListingDictionary is an"
    " abstract class!"];
  return nil;
}


- (NSUInteger)sourceLineForAddress:(NSNumber *)n {
  [NSException raise:NSGenericException format:@"MOSListingDictionary is an"
    " abstract class!"];
  return NSNotFound;
}


@end
