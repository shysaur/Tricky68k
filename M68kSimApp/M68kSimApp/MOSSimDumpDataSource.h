//
//  MOSSimDumpDataSource.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 31/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>
#import "MOSSimTableViewDelegate.h"


@interface MOSSimDumpDataSource : MOSSimTableViewDelegate <NSTableViewDataSource> {
  NSUInteger maxLines;
}

@end
