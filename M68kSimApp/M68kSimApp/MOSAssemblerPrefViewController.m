//
//  MOSAssemblerPrefViewController.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 23/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSAssemblerPrefViewController.h"


@implementation MOSAssemblerPrefViewController


- init {
  return [super initWithNibName:@"MOSAssemblerPrefView" bundle:[NSBundle mainBundle]];
}


@end


@implementation MOSAssemblerPrefViewEntryPointInfoValueTransformer


+ (Class)transformedValueClass {
  return [NSString class];
}


+ (BOOL)allowsReverseTransformation {
  return NO;
}


- (id)transformedValue:(id)beforeObject {
  if (beforeObject == nil) return nil;
  if ([beforeObject boolValue])
    return NSLocalizedString(@"The entry point of the program will always be "
      "located at $2000, regardless of the location of your start label.",
      @"Info about what happens when entry point is fixed");
  else
    return NSLocalizedString(@"The entry point of the program will be located "
      "where you place a global label named \"start\".", @"Info about what "
      "happens when entry point is not fixed (uses start symbol)");
}

  
@end


@implementation MOSAssemblerPrefViewOptimizationInfoValueTransformer


+ (Class)transformedValueClass {
  return [NSString class];
}


+ (BOOL)allowsReverseTransformation {
  return NO;
}


- (id)transformedValue:(id)beforeObject {
  if (beforeObject == nil) return nil;
  if (![beforeObject boolValue])
    return NSLocalizedString(@"The assembler output will contain exactly the "
      "instructions you specified in the source file.",  @"Info about what "
      "happens when assembler optimizations are disabled");
  else
    return NSLocalizedString(@"The assembler will replace your instructions "
      "with shorter or faster equivalents, if available.", @"Info about what "
      "happens when assembler optimizations are enabled");
}


@end





