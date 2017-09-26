//
//  MOSAssembler.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 09/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOS68kAssembler.h"
#import "MOS68kListingDictionary.h"
#import "MOSMonitoredTask.h"


@interface MOS68kAssembler ()

@property (nonatomic) MOSExecutable *output;

@end


@implementation MOS68kAssembler


- (BOOL)prepareForAssembling
{
  gotWarnings = NO;
  sections = [NSMutableArray array];
  return [super prepareForAssembling];
}


- (MOSAssemblageResult)assembleThread
{
  MOSAssemblageResult asmResult;
  MOSMonitoredTask *task;
  NSURL *execurl;
  NSURL *linkerfile;
  NSURL *listingfile;
  NSURL *outputfile;
  NSMutableArray *params;
  NSError *terr;
  NSDictionary *lfevent;
  
  linking = NO;
  
  task = [[MOSMonitoredTask alloc] init];
  execurl = [[NSBundle bundleForClass:[self class]] URLForAuxiliaryExecutable:@"vasmm68k-mot"];
  [task setLaunchURL:execurl];
  
  NSURL *unlinkedelf = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
  
  NSURL *sourcefile = [NSURL URLWithTemporaryFilePathWithExtension:@"asm"];
  NSData *sourcedata = [self.sourceCode dataUsingEncoding:NSUTF8StringEncoding];
  if (![sourcedata writeToURL:sourcefile options:0 error:&terr]) {
    NSString *basee = MOSPlatformLocalized(@"Could not write the temporary "
      "source code file. ", @"Text of the event which occurs when failing to "
      "write a temporary file while assembling. Concatenated with the reason "
      "for the error.");
    NSString *errs = [basee stringByAppendingString:[terr localizedDescription]];
    NSDictionary *sfevent = @{MOSJobEventType: MOSJobEventTypeError,
                              MOSJobEventText: errs};
    dispatch_async(dispatch_get_main_queue(), ^{
      [[self jobStatus] addEvent:sfevent];
    });
    return MOSAssemblageResultFailure;
  }
  
  params = [@[@"-Felf", @"-spaces"] mutableCopy];
  if (!([self assemblageOptions] & MOSAssemblageOptionOptimizationOn))
    [params addObject:@"-no-opt"];
  [params addObjectsFromArray:@[@"-o", [unlinkedelf path], [sourcefile path]]];
  if (self.produceListingDictionary) {
    listingfile = [NSURL URLWithTemporaryFilePathWithExtension:@"lst"];
    [params addObjectsFromArray:@[@"-L", [listingfile path]]];
  }
  
  [task setArguments:params];
  [task setDelegate:self];
  [task launch];
  [task waitUntilExit];
  if ([task terminationStatus] != 0) goto fail;
  
  linking = YES;
  task = [[MOSMonitoredTask alloc] init];
  execurl = [[NSBundle bundleForClass:[self class]] URLForAuxiliaryExecutable:@"m68k-elf-ld"];
  [task setLaunchURL:execurl];
  linkerfile = [NSURL URLWithTemporaryFilePathWithExtension:@"ld"];
  if (![self makeLinkerFile:linkerfile]) {
    [[self jobStatus] addEvent:@{
      MOSJobEventType: MOSJobEventTypeError,
      MOSJobEventText: MOSPlatformLocalized(@"Could not create a linker file.",
        @"Text of the event which occurs when creating a linker file failed.")
      }];
    goto fail;
  }
  
  outputfile = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
  
  params = [NSMutableArray array];
  if (!([self assemblageOptions] & MOSAssemblageOptionEntryPointSymbolic))
    [params addObject:@"--entry=0x2000"];
  else
    [params addObject:@"--entry=start"];
  [params addObjectsFromArray:@[@"-o", [outputfile path], @"-T", [linkerfile path]]];
  [params addObjectsFromArray:@[[unlinkedelf path]]];
  
  [task setArguments:params];
  [task setDelegate:self];
  [task launch];
  [task waitUntilExit];
  if ([task terminationStatus] != 0)
    goto fail;
  
  if (self.produceListingDictionary) {
    listingDict = [[MOS68kListingDictionary alloc]
      initWithListingFile:listingfile error:&terr];
    if (!listingDict) {
      lfevent = @{MOSJobEventType: MOSJobEventTypeWarning,
       MOSJobEventText: MOSPlatformLocalized(@"Could not read the listing file",
         @"Text of the event which occurs when failing to read a listing "
         "file.")};
      dispatch_async(dispatch_get_main_queue(), ^{
        [[self jobStatus] addEvent:lfevent];
      });
      gotWarnings = YES;
    }
  }
  
  self.output = [[MOSFileBackedExecutable alloc] initWithPersistentURL:outputfile error:nil];
  
  if (gotWarnings)
    asmResult = MOSAssemblageResultSuccessWithWarning;
  else
    asmResult = MOSAssemblageResultSuccess;
  goto finish;
fail:
  asmResult = MOSAssemblageResultFailure;
finish:
  unlink([sourcefile fileSystemRepresentation]);
  unlink([unlinkedelf fileSystemRepresentation]);
  unlink([linkerfile fileSystemRepresentation]);
  unlink([listingfile fileSystemRepresentation]);
  
  return asmResult;
}


- (BOOL)makeLinkerFile:(NSURL*)ld {
  int fh;
  const char *sns;
  uint32_t segment_addr;
  NSString *section;
  NSFileHandle *nfh;
  BOOL isAbsolute, res;
  
  fh = open([ld fileSystemRepresentation], O_WRONLY | O_CREAT | O_EXCL, 0666);
  if (fh < 0) return NO;
  nfh = [[NSFileHandle alloc] initWithFileDescriptor:fh closeOnDealloc:YES];
  if (!nfh) return NO;
  
  res = YES;
  @try {
    [nfh writeString:
     @"MEMORY {\n"
      "  vectors(rw) : ORIGIN = 0x00000000, LENGTH = 0x00000400\n"
      "  ram(rwx)    : ORIGIN = 0x00000400, LENGTH = 0x01000000\n"
      "}\n"];
    
    [nfh writeLine:@"SECTIONS {"];
    for (section in sections) {
      [nfh writeString:section];
      [nfh writeString:@" "];
      sns = [section UTF8String];
      if (strstr(sns, "seg") == sns) {
        isAbsolute = YES;
        sscanf(sns+3, "%x", &segment_addr);
        [nfh writeString:[NSString stringWithFormat:@"0x%X ", segment_addr]];
      } else
        isAbsolute = NO;
      [nfh writeString:@": { *("];
      [nfh writeString:section];
      [nfh writeString:@") }"];
      if (!isAbsolute)
        [nfh writeLine:@" > ram"];
      else
        [nfh writeLine:@""];
    }
    [nfh writeLine:@"}"];
  } @catch (NSException *exc) {
    res = NO;
  }
  
  [nfh closeFile];
  return res;
}


- (void)receivedTaskOutput:(NSString *)line {
  NSDictionary *event;

  if (![self jobStatus])
    NSLog(@"taskoutput: %@", line);
  else {
    if (!linking)
      event = [self parseVasmOutput:line];
    else
      event = [self parseLinkerOutput:line];
    if (event)
      [[self jobStatus] addEvent:event];
  }
}


- (NSDictionary*)parseVasmOutput:(NSString *)line {
  NSMutableDictionary *res;
  NSScanner *scan;
  NSInteger lineno;
  NSString *secname;
  BOOL isFatal;
  
  scan = [NSScanner scannerWithString:line];
  res = [NSMutableDictionary dictionary];
  
  /* No empty lines thanks */
  if ([line isEqual:@""]) return nil;
  /* Filter out the banner */
  if ([scan scanString:@"vasm "]) return nil;
  /* Source code line echo: filter out */
  if ([scan scanString:@">"]) return nil;
  
  /* Pass nesting info lines as found */
  if ([scan scanString:@"called"] || [scan scanString:@"included"])
    goto returnAsIs;
  
  isFatal = [scan scanString:@"fatal"];
  if ([scan scanString:@"error"])
    [res setObject:MOSJobEventTypeError forKey:MOSJobEventType];
  else if ([scan scanString:@"message"])
    [res setObject:MOSJobEventTypeMessage forKey:MOSJobEventType];
  else if ([scan scanString:@"warning"]) {
    [res setObject:MOSJobEventTypeWarning forKey:MOSJobEventType];
    gotWarnings = YES;
  } else {
    /* No error|message|warning header: might be a section name */
    /* Section name is terminated by an open parens */
    if (![scan scanUpToString:@"(" intoString:&secname]) goto returnAsIs;
    /* The line must end by the "bytes" string */
    [scan scanUpToString:@"bytes"];
    if (![scan scanString:@"bytes"]) goto returnAsIs;
    /* If both of these conditions are fulfilled, add a section to the array */
    [sections addObject:secname];
    return nil;
  }
  /* skip eventual error number */
  [scan scanInteger:NULL];
  
  /* Check for line numbers */
  if ([scan scanString:@"in line"]) {
    if (![scan scanInteger:&lineno]) goto returnAsIs;
    [res setObject:[NSNumber numberWithInteger:lineno] forKey:MOSJobEventAssociatedLine];
    [scan scanUpToString:@"\": "];
    if (![scan scanString:@"\": "]) goto returnAsIs;
  } else {
    [scan scanUpToString:@": "];
    if (![scan scanString:@": "]) goto returnAsIs;
  }
  
  [res setObject:[scan scanUpToEndOfString] forKey:MOSJobEventText];
  if (isFatal) [res setObject:MOSJobEventTypeError forKey:MOSJobEventType];
  
  return [res copy];
  
returnAsIs:
  [res setObject:line forKey:MOSJobEventText];
  [res setObject:MOSJobEventTypeMessage forKey:MOSJobEventType];
  return [res copy];
}


- (NSDictionary*)parseLinkerOutput:(NSString *)line {
  NSMutableDictionary *res;
  NSScanner *scan;
  
  scan = [NSScanner scannerWithString:line];
  res = [NSMutableDictionary dictionary];
  
  /* Skip the filename */
  [scan scanUpToString:@":"];
  if (![scan scanString:@":"]) goto returnAsIs;
  
  if ([scan scanString:@"warning: "]) {
    gotWarnings = YES;
    [res setObject:MOSJobEventTypeWarning forKey:MOSJobEventType];
  } else
    [res setObject:MOSJobEventTypeError forKey:MOSJobEventType];
  
  /* Return the rest of the line as a message */
  [res setObject:[scan scanUpToEndOfString] forKey:MOSJobEventText];
  return [res copy];
  
returnAsIs:
  [res setObject:line forKey:MOSJobEventText];
  [res setObject:MOSJobEventTypeMessage forKey:MOSJobEventType];
  return [res copy];
}


- (MOSListingDictionary *)listingDictionary {
  if (!self.isComplete)
    [NSException raise:NSInvalidArgumentException
                format:@"Assemblage is not complete yet."];
  return listingDict;
}


- (void)setProduceListingDictionary:(BOOL)pl
{
  if ([self isAssembling] | [self isComplete])
    [NSException raise:NSInvalidArgumentException
                format:@"Can't change parameters after assembling."];
  _produceListingDictionary = pl;
}


@end
