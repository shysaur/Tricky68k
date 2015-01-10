//
//  Document.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 29/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import "MOSSource.h"
#import <MGSFragaria/MGSFragaria.h>
#import "NSURL+TemporaryFile.h"
#import "MOSAssembler.h"


static void *AssemblageEvent = &AssemblageEvent;


@implementation MOSSource


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  [super windowControllerDidLoadNib:aController];
  
  fragaria = [[MGSFragaria alloc] init];
  [fragaria setObject:self forKey:MGSFODelegate];
  [fragaria embedInView:editView];
  
  [fragaria setObject:@"VASM Motorola 68000 Assembly" forKey:MGSFOSyntaxDefinitionName];
  [fragaria setObject:@YES forKey:MGSFOIsSyntaxColoured];
  [fragaria setObject:@YES forKey:MGSFOShowLineNumberGutter];
  if (initialData) {
    [self loadData:initialData];
    initialData = nil;
  }
  
  textView = [fragaria objectForKey:ro_MGSFOTextView];
}


- (NSString *)windowNibName {
  return @"MOSSource";
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
  NSTextStorage *ts;
  NSRange allRange;
  NSDictionary *opts;
  NSData *res;
  NSNumber *enc;
  
  enc = [NSNumber numberWithInteger:NSUTF8StringEncoding];
  opts = @{NSDocumentTypeDocumentOption: NSPlainTextDocumentType,
           NSCharacterEncodingDocumentAttribute: enc};
  ts = [textView textStorage];
  
  allRange.length = [ts length];
  allRange.location = 0;
  res = [ts dataFromRange:allRange documentAttributes:opts error:outError];
  return res;
}


- (void)loadData:(NSData*)data {
  NSString *tmp;
  
  tmp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  [fragaria setString:tmp];
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
  if (fragaria)
    [self loadData:data];
  else
    initialData = data;
  return YES;
}


- (IBAction)assembleAndRun:(id)sender {
  NSURL *tempSourceCopy;
  
  if (assembler) return;
  
  assemblyOutput = [NSURL URLWithTemporaryFilePathWithExtension:@"o"];
  @try {
    [assembler removeObserver:self forKeyPath:@"complete" context:AssemblageEvent];
  } @finally {}
  assembler = [[MOSAssembler alloc] init];
  [assembler addObserver:self forKeyPath:@"complete" options:0 context:AssemblageEvent];
  [assembler setOutputFile:assemblyOutput];
  
  tempSourceCopy = [NSURL URLWithTemporaryFilePathWithExtension:@"s"];
  [self saveToURL:tempSourceCopy ofType:@"public.plain-text"
    forSaveOperation:NSSaveToOperation completionHandler:^(NSError *err){
      if (err) {
        [assembler removeObserver:self forKeyPath:@"complete" context:AssemblageEvent];
        assembler = nil;
        return;
      }
      [assembler setSourceFile:tempSourceCopy];
      [assembler assemble];
  }];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context {
  if (context == AssemblageEvent) {
    NSLog(@"Assemblage has finished");
    if ([assembler assemblageResult] == MOSAssemblageResultFailure) {
      NSLog(@"Assemblage failed");
    } else {
      [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:assemblyOutput display:YES completionHandler:nil];
    }
    [assembler removeObserver:self forKeyPath:@"complete" context:AssemblageEvent];
    assembler = nil;
  } else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


@end
