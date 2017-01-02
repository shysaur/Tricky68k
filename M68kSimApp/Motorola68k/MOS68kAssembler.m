//
//  MOSAssembler.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 09/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOS68kAssembler.h"
#import "NSURL+TemporaryFile.h"
#import "NSFileHandle+Strings.h"
#import "MOSJob.h"
#import "NSScanner+Shorteners.h"
#import "MOS68kListingDictionary.h"


@implementation MOS68kAssembler


- (instancetype)init {
  self = [super init];
  running = NO;
  completed = NO;
  return self;
}


- (void)assemble {
  if (running || completed)
    [NSException raise:NSInvalidArgumentException
      format:@"Already assembled once."];
  if (![self sourceFile] || ![self outputFile])
    [NSException raise:NSInvalidArgumentException
      format:@"Source file and output file not specified"];
  
  [self setAssembling:YES];
  
  gotWarnings = NO;
  sections = [NSMutableArray array];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    MOSMonitoredTask *task;
    NSURL *execurl;
    NSURL *unlinkedelf;
    NSURL *linkerfile;
    NSMutableArray *params;
    NSError *lfe;
    NSDictionary *lfevent;
    
    linking = NO;
    task = [[MOSMonitoredTask alloc] init];
    execurl = [[NSBundle bundleForClass:[self class]] URLForAuxiliaryExecutable:@"vasmm68k-mot"];
    [task setLaunchURL:execurl];
    unlinkedelf = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
    
    params = [@[@"-Felf", @"-spaces"] mutableCopy];
    if (!([self assemblageOptions] & MOSAssemblageOptionOptimizationOn))
      [params addObject:@"-no-opt"];
    [params addObjectsFromArray:@[@"-o", [unlinkedelf path], [[self sourceFile] path]]];
    if ([self outputListingFile])
      [params addObjectsFromArray:@[@"-L", [[self outputListingFile] path]]];
    
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
        MOSJobEventText: NSLocalizedString(@"Could not create a linker file.",
          @"Text of the event which occurs when creating a linker file failed.")
        }];
      goto fail;
    }
    
    params = [NSMutableArray array];
    if (!([self assemblageOptions] & MOSAssemblageOptionEntryPointSymbolic))
      [params addObject:@"--entry=0x2000"];
    else
      [params addObject:@"--entry=start"];
    [params addObjectsFromArray:@[@"-o", [[self outputFile] path], @"-T", [linkerfile path]]];
    [params addObjectsFromArray:@[[unlinkedelf path]]];
    
    [task setArguments:params];
    [task setDelegate:self];
    [task launch];
    [task waitUntilExit];
    if ([task terminationStatus] != 0)
      goto fail;
    
    if ([self outputListingFile]) {
      listingDict = [[MOS68kListingDictionary alloc]
        initWithListingFile:[self outputListingFile] error:&lfe];
      if (!listingDict) {
        lfevent = @{MOSJobEventType: MOSJobEventTypeWarning,
         MOSJobEventText: NSLocalizedString(@"Could not read the listing file",
           @"Text of the event which occurs when failing to read a listing "
           "file.")};
        dispatch_async(dispatch_get_main_queue(), ^{
          [[self jobStatus] addEvent:lfevent];
        });
        gotWarnings = YES;
      }
    }
    
    if (gotWarnings)
      asmResult = MOSAssemblageResultSuccessWithWarning;
    else
      asmResult = MOSAssemblageResultSuccess;
    goto finish;
  fail:
    asmResult = MOSAssemblageResultFailure;
  finish:
    unlink([unlinkedelf fileSystemRepresentation]);
    unlink([linkerfile fileSystemRepresentation]);
    dispatch_async(dispatch_get_main_queue(), ^{
      [self setComplete:YES];
      [self setAssembling:NO];
      
      [[self jobStatus] setStatus:MOSAsmResultToJobStat(asmResult)];
    });
  });
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


- (void)setAssembling:(BOOL)a {
  running = a;
}


- (BOOL)isAssembling {
  return running;
}


- (void)setComplete:(BOOL)c {
  completed = c;
}


- (BOOL)isComplete {
  return completed;
}


- (MOSAssemblageResult)assemblageResult {
  if (!completed)
    [NSException raise:NSInvalidArgumentException
      format:@"Assemblage is not complete yet."];
  return asmResult;
}


- (MOSListingDictionary *)listingDictionary {
  if (!completed)
    [NSException raise:NSInvalidArgumentException
                format:@"Assemblage is not complete yet."];
  return listingDict;
}


@end
