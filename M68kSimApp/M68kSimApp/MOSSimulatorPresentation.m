//
//  MOSSimulatorPresentation.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 10/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimulatorPresentation.h"
#import "MOSSimulator.h"


#define SUBCLASS_MUST_IMPLEMENT(x) { \
  [NSException raise:NSGenericException format:@"You should implement this"]; \
  return x; \
}


@implementation MOSSimulatorPresentation


- (instancetype)initWithSimulator:(MOSSimulator *)s {
  return [super init];
}

@end
