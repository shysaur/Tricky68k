//
//  MOSAssemblerOutput.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/08/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MOSExecutable : NSObject

- (instancetype)initWithURL:(NSURL *)rep error:(NSError **)errptr;
- (BOOL)writeToURL:(NSURL *)outf error:(NSError **)errptr;

@end
