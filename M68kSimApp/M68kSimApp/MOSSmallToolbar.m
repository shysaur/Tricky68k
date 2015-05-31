//
//  MOSSmallToolbar.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 19/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSSmallToolbar.h"


@implementation MOSSmallToolbar


- (BOOL)_allowsSizeMode:(NSToolbarSizeMode)mode {
  return mode != NSToolbarSizeModeRegular;
}


@end
