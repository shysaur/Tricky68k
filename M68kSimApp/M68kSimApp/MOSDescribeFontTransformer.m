//
//  MOSDescribeFontTransformer.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 21/04/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSDescribeFontTransformer.h"


static NSNumberFormatter *ptSizeFormatter;


@implementation MOSDescribeFontTransformer


+ (Class)transformedValueClass {
  return [NSString class];
}


+ (BOOL)allowsReverseTransformation {
  return NO;
}


- (instancetype)init {
  static dispatch_once_t onceToken;
  
  self = [super init];
  dispatch_once(&onceToken, ^{
    ptSizeFormatter = [[NSNumberFormatter alloc] init];
    [ptSizeFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
  });
  return self;
}


- (id)transformedValue:(NSFont *)font {
  NSNumber *size;
  NSString *sizeString;
  NSString *name;
  
  size = [NSNumber numberWithFloat:[font pointSize]];
  sizeString = [ptSizeFormatter stringFromNumber:size];
  name = [font displayName];
  return [NSString stringWithFormat:@"%@ – %@", name, sizeString];
}


@end


@implementation MOSDescribeArchivedFontTransformer


- (id)transformedValue:(NSData *)font {
  return [super transformedValue:[NSUnarchiver unarchiveObjectWithData:font]];
}


@end


