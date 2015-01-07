//
//  MOSNamedPipe.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MOSNamedPipe : NSObject {
  NSFileHandle *readFh;
  NSFileHandle *writeFh;
  NSURL *mount;
}

+ pipe;

- (NSURL*)pipeURL;
- (NSFileHandle *)fileHandleForReading;
- (NSFileHandle *)fileHandleForWriting;

@end
