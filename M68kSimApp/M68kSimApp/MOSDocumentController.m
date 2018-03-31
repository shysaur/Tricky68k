//
//  MOSDocumentController.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 18/03/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSDocumentController.h"
#import "MOSDocument.h"


@implementation MOSDocumentController


- (instancetype)init {
  self = [super init];
  transientClose = [[NSLock alloc] init];
  return self;
}


- (id)openUntitledDocumentAndDisplay:(BOOL)disp error:(NSError *__autoreleasing *)err {
  MOSDocument *doc;
  
  doc = [super openUntitledDocumentAndDisplay:disp error:err];
  if ([[self documents] count] == 1)
    [doc setTransient:YES];
  return doc;
}


- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)disp completionHandler:(nonnull void (^)(NSDocument * _Nullable, BOOL, NSError * _Nullable))completionHandler
{
  MOSDocument *firstDoc;
  
  [transientClose lock];
  if ([[self documents] count] == 1) {
    firstDoc = [[self documents] firstObject];
    if ([firstDoc isTransient])
      [firstDoc close];
  }
  [transientClose unlock];
  
  [super openDocumentWithContentsOfURL:url display:disp completionHandler:completionHandler];
}


@end
