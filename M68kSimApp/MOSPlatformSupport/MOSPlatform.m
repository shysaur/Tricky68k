//
//  MOSPlatform.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 11/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSPlatform.h"


@implementation MOSPlatform


- (NSBundle *)bundle {
  return [NSBundle bundleForClass:[self class]];
}


- (NSString *)description {
  return [NSString stringWithFormat:
    @"<MOSPlatform %p name: %@ assembler: %@ simulator: %@>",
    self, _localizedName, _assemblerClass, _simulatorClass];
}


- (NSURL *)URLForExampleFile:(NSString *)fn {
  return nil;
}


- (NSViewController *)assemblerPreferencesViewController {
  return nil;
}


- (NSViewController *)simulatorPreferencesViewController {
  return nil;
}


@end
