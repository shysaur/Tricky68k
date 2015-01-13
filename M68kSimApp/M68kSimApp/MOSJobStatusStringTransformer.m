//
//  MOSJobStatusStringTransformer.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 13/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSJobStatusStringTransformer.h"


@implementation MOSJobStatusStringTransformer


+ (Class)transformedValueClass {
  return [NSString class];
}


+ (BOOL)allowsReverseTransformation {
  return NO;
}


- (id)transformedValue:(id)beforeObject {
  if (beforeObject == nil) return nil;
  return [[NSBundle mainBundle] URLForResource:beforeObject withExtension:@"tiff"];
}


@end
