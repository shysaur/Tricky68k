//
//  MOSPlatform.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 11/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSPlatform.h"


@implementation MOSPlatform


+ (instancetype)platformWithAssemblerClass:(Class)a simulatorClass:(Class)s
                         presentationClass:(Class)p localizedName:(NSString *)d {
  return [[[self class] alloc] initWithAssemblerClass:a simulatorClass:s
                                    presentationClass:p localizedName:d];
}


- (instancetype)initWithAssemblerClass:(Class)a simulatorClass:(Class)s
                     presentationClass:(Class)p localizedName:(NSString *)d {
  self = [super init];
  _assemblerClass = a;
  _simulatorClass = s;
  _presentationClass = p;
  _localizedName = d;
  return self;
}


- (NSString *)description {
  return [NSString stringWithFormat:
    @"<MOSPlatform %p name: %@ assembler: %@ simulator: %@>",
    self, _localizedName, _assemblerClass, _simulatorClass];
}


@end
