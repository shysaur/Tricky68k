//
//  MOSFileBackedExecutable.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/08/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import "MOSFileBackedExecutable.h"
#import "PlatformSupport.h"


@implementation MOSFileBackedExecutable


- (instancetype)initWithPersistentURL:(NSURL *)rep withError:(NSError **)errptr
{
  self = [super init];
  _executableFile = rep;
  MOSDbgLog(@"MOSFileBackedExecutable: acquired %@", rep);
  return self;
}


- (instancetype)initWithURL:(NSURL *)rep withError:(NSError **)errptr
{
  self = [super init];
  NSFileManager *fm = [NSFileManager defaultManager];
  _executableFile = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
  BOOL res = [fm copyItemAtURL:rep toURL:_executableFile error:errptr];
  if (res) {
    MOSDbgLog(@"MOSFileBackedExecutable: created %@ (from %@)", _executableFile, rep);
    return self;
  }
  return nil;
}


- (BOOL)writeToURL:(NSURL *)outf withError:(NSError **)errptr
{
  /* Q: Why are you using NSData instead of NSFileManager or copyfile(3)? This
   *    way you are missing out on all the APFS awesomeness!
   * A: Because NEITHER of them actually returns ANY usable ERROR CODE.
   *    IN 2017. * angrily punches a fist through the air * NSFileManager
   *    always returns a non-descript error with an underlying NSError of
   *    EIO, which is useless (and a lie unless your disk is broken,
   *    so it's even a dangerous lie to tell). copyfile(3) is meant to return
   *    an error in errno, but for some reason we actually always get zero...
   *    which is a problem of errno more than copyfile(3) but come on, everyone
   *    knows about that and designs their APIs so that they return an error
   *    code instead of relying on errno in 2017... But, the authors of
   *    copyfile are not capable of doing that. I must assume AppKit and the
   *    POSIX layer are both maintained by the worst interns imaginable.
   *    Now my faith in humanity has dropped to a new low, thanks Apple. */
  NSData *tmp = [NSData dataWithContentsOfURL:self.executableFile
    options:NSDataReadingMappedAlways error:errptr];
  if (!tmp)
    return NO;
  if (![tmp writeToURL:outf options:0 error:errptr])
    return NO;
  return YES;
}


- (void)dealloc
{
  unlink([self.executableFile fileSystemRepresentation]);
  MOSDbgLog(@"MOSFileBackedExecutable: deleted %@", self.executableFile);
}


@end
