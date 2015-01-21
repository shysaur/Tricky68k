//
//  MOSTeletypeViewDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSTeletypeViewDelegate.h"
#import "MOSSimulatorProxy.h"
#import "MOSTeletypeView.h"


@implementation MOSTeletypeViewDelegate


- init {
  self = [super init];

  lineBuffer = [[NSMutableString alloc] init];
  cursor = viewCursor = viewSpan = 0;
  
  return self;
}


- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp {
  simProxy = sp;
  toSim = [simProxy teletypeOutput];
  fromSim = [simProxy teletypeInput];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSData *temp;
    
    temp = [fromSim readDataOfLength:1];
    while ([temp length]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        NSString *string;
        
        string = [[NSString alloc] initWithData:temp encoding:NSISOLatin1StringEncoding];
        [self echoString:string];
      });
      temp = [fromSim readDataOfLength:1];
    }
  });
}


- (void)defaultMonospacedFontHasChanged {
  [textView setTeletypeFont:[self defaultMonospacedFont]];
}


- (void)typedString:(NSString *)str {
  NSString *tmp;
  const char *buf, *newline;
  
  buf = [str UTF8String];
  newline = strstr(buf, "\n");
  while (newline) {
    newline++;
    tmp = [[NSString alloc] initWithBytes:buf length:(newline-buf)
      encoding:NSUTF8StringEncoding];
    [self insertString:str];
    [self flushBuffer];
    buf = newline;
    newline = strstr(buf, "\n");
  }
  [self insertString:[NSString stringWithUTF8String:buf]];
}


- (void)insertString:(NSString*)str {
  NSRange range;
  
  if ([lineBuffer length] == cursor) {
    [lineBuffer appendString:str];
  } else {
    range.length = [str length];
    range.location = cursor;
    if (range.location + range.length > [lineBuffer length])
      range.length = [lineBuffer length] - range.location;
    [lineBuffer replaceCharactersInRange:range withString:str];
  }
  cursor += [str length];
  [self updateLineBufferEcho];
}


- (void)flushBuffer {
  NSData *data;
  
  data = [lineBuffer dataUsingEncoding:NSISOLatin1StringEncoding];
  [toSim writeData:data];
  lineBuffer = [[NSMutableString alloc] init];
  cursor = viewSpan = 0;
}


- (void)moveCursor:(NSInteger)displ {
  cursor += displ;
  if (cursor < 0)
    cursor = 0;
  else if (cursor > [lineBuffer length])
    cursor = [lineBuffer length];
  [self updateLineBufferEcho];
}


- (void)deleteCharactersFromCursor:(NSInteger)amount {
  NSRange range;
  
  if (amount == 0)
    return;
  else if (amount > 0) {
    range.length = amount;
    if (cursor + range.length > [lineBuffer length])
      range.length = [lineBuffer length] - cursor;
  } else {
    range.length = -amount;
    cursor += amount;
    if (cursor < 0) {
      range.length += cursor;
      cursor = 0;
    }
  }
  range.location = cursor;
  [lineBuffer replaceCharactersInRange:range withString:@""];
  [self updateLineBufferEcho];
}


- (void)updateLineBufferEcho {
  NSTextStorage *ts;
  NSRange range, selRange;
  
  ts = [textView textStorage];
  if ([ts length] == viewCursor) {
    range.length = viewSpan;
    range.location = viewCursor - range.length;
  } else {
    range.length = 0;
    range.location = [ts length];
  }

  [ts replaceCharactersInRange:range withString:lineBuffer];
  viewCursor = [ts length];
  viewSpan = [lineBuffer length];
  
  /* This is just for show. Also makes text draw faster for some reason. */
  selRange.location = ([ts length] - viewSpan) + cursor;
  selRange.length = 0;
  [textView setSelectedRange:selRange];
  /* This is the real cursor */
  [textView setTeletypeFormat];
  [textView setTeletypeCursorPosition:selRange.location];
}


- (void)echoString:(NSString*)str {
  NSTextStorage *ts;
  NSAttributedString *attrs;
  
  ts = [textView textStorage];
  attrs = [[NSAttributedString alloc] initWithString:str];
  [ts appendAttributedString:attrs];
  [textView setTeletypeFormat];
  
  [textView setTeletypeCursorPosition:([ts length] - [lineBuffer length]) + cursor];
}


@end
