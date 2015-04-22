//
//  MOSDescribeFontTransformer.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 21/04/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSDescribeArchivedFontTransformer.h"


@implementation MOSDescribeArchivedFontTransformer


+ (Class)transformedValueClass {
  return [NSString class];
}


+ (BOOL)allowsReverseTransformation {
  return NO;
}


- (instancetype)init {
  self = [super init];
  ptSizeFormatter = [[NSNumberFormatter alloc] init];
  [ptSizeFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
  return self;
}


- (id)transformedValue:(NSData *)value {
  NSNumber *size;
  NSString *sizeString;
  NSString *name;
  NSFont *font;
  
  font = [NSUnarchiver unarchiveObjectWithData:value];
  size = [NSNumber numberWithFloat:[font pointSize]];
  sizeString = [ptSizeFormatter stringFromNumber:size];
  name = [font displayName];
  return [NSString stringWithFormat:@"%@ – %@", name, sizeString];
}


@end
