//
//  MOSColourSchemeListController.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 07/07/2019.
//  Copyright © 2019 Daniele Cattaneo. All rights reserved.
//

#import "MOSColourSchemeListController.h"


@implementation MOSColourSchemeListController


- (void)awakeFromNib
{
  if (!self.defaultScheme)
    self.defaultScheme = super.defaultScheme;
  [super awakeFromNib];
}


@synthesize defaultScheme;


- (NSArray <MGSColourSchemeOption *> *)loadColourSchemes
{
  /* only show application-specific schemes */
  return [self loadApplicationColourSchemes];
}


@end
