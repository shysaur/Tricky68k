//
//  MOSFileBackedExecutable.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/08/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import "MOSExecutable.h"


@interface MOSFileBackedExecutable : MOSExecutable

- (instancetype)initWithPersistentURL:(NSURL *)rep withError:(NSError **)errptr;

@property (nonatomic, readonly) NSURL *executableFile;

@end
