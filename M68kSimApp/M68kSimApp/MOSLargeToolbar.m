//
//  MOSLargeToolbar.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/11/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSLargeToolbar.h"


@implementation MOSLargeToolbar


- (BOOL)_allowsSizeMode:(NSToolbarSizeMode)mode {
  return mode != NSToolbarSizeModeSmall;
}


@end
