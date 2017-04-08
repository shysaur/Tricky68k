//
//  MOSDocument.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 18/03/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>


@interface MOSDocument : NSDocument

@property (nonatomic, getter=isTransient) BOOL transient;

- (NSTouchBar *)makeTouchBar;

@end
