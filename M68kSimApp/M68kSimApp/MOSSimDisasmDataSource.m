//
//  MOSSimDisasmDataSource.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 01/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSSimDisasmDataSource.h"
#import "MOS68kSimulator.h"


@implementation MOSSimDisasmDataSource


+ (void)load {
  NSUserDefaults *ud;
  
  ud = [NSUserDefaults standardUserDefaults];
  [ud registerDefaults:@{
    @"DisassemblyLines": @1500
  }];
}


- init {
  NSUserDefaults *ud;
  
  self = [super init];
  
  ud = [NSUserDefaults standardUserDefaults];
  maxLines = [ud integerForKey:@"DisassemblyLines"];
  if (maxLines < 25) maxLines = 1501;
  maxLines |= 1; /* always odd */
  
  return self;
}


- (void)setSimulatorProxy:(MOS68kSimulator*)sp {
  NSInteger rows;
  NSRect visibleRect;
  
  [super setSimulatorProxy:sp];
  
  visibleRect = [tableView visibleRect];
  rows = [tableView rowsInRect:visibleRect].length;
  [tableView scrollRowToVisible:[self programCounterRow]+rows/2];
}


- (IBAction)clickedTableView:(id)sender {
  NSInteger row;
  uint32_t addr;
  BOOL hasBreakpt;
  
  if ([tableView clickedColumn] == 0) {
    row = [tableView clickedRow];
    addr = [self getAddressForLine:row];
    hasBreakpt = [breakpoints containsObject:[NSNumber numberWithUnsignedInt:addr]];
    if (!hasBreakpt) {
      [simProxy addBreakpointAtAddress:addr];
    } else {
      [simProxy removeBreakpointAtAddress:addr];
    }
    [self dataHasChanged];
  }
}


- (void)dataHasChanged {
  if (![simProxy isSimulatorRunning])
    [self refreshSimulatorData];
  [super dataHasChanged];
}


- (void)refreshSimulatorData {
  NSDictionary *regs;
  
  breakpoints = [simProxy breakpointList];
  regs = [simProxy registerDump];
  centerAddr = [[regs objectForKey:MOS68kRegisterPC] unsignedIntValue];
  lineCache = [[self disassemble:1 instructionsFromLocation:centerAddr] mutableCopy];
  cacheStart = (maxLines - 1) / 2;
  addrCacheStart = addrCacheEnd = centerAddr;
}


- (NSInteger)programCounterRow {
  return (maxLines-1)/2+1;
}


- (void)updateCacheStartAddress {
  NSString *line;
  const char *str;
  
  line = [lineCache firstObject];
  if (line) {
    str = [line UTF8String];
    sscanf(str+2, "%X", &addrCacheStart);
  }
}


- (void)updateCacheEndAddress {
  NSString *line;
  const char *str;
  
  line = [lineCache lastObject];
  if (line) {
    str = [line UTF8String];
    sscanf(str+2, "%X", &addrCacheEnd);
  }
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return maxLines;
}


- (NSString *)getLine:(NSInteger)row {
  NSInteger linestodo;
  NSArray *add;
  NSMutableArray *newcache;
  
  if (row < cacheStart) {
    linestodo = row - cacheStart;
    add = [self disassemble:linestodo instructionsFromLocation:addrCacheStart];
    newcache = [add mutableCopy];
    [newcache addObjectsFromArray:lineCache];
    lineCache = newcache;
    cacheStart = row;
    [self updateCacheStartAddress];
  } else if (row >= cacheStart + [lineCache count]) {
    linestodo = row - (cacheStart + [lineCache count]) + 1;
    add = [self disassemble:linestodo+1 instructionsFromLocation:addrCacheEnd];
    newcache = [add mutableCopy];
    [newcache removeObjectAtIndex:0];
    [lineCache addObjectsFromArray:newcache];
    [self updateCacheEndAddress];
  }
  return [lineCache objectAtIndex:row - cacheStart];
}


- (NSArray *)disassemble:(NSInteger)c instructionsFromLocation:(uint32_t)addr {
  NSArray *res;
  NSMutableArray *tmp;
  NSInteger i;
  
  res = [simProxy disassemble:(int)c instructionsFromLocation:addr];
  if (!res || [res count] < ABS(c)) {
    tmp = [NSMutableArray array];
    for (i=0; i<c; i++)
      [tmp addObject:@""];
    return tmp;
  }
  return res;
}


- (uint32_t)getAddressForLine:(NSInteger)row {
  NSString *line;
  uint32_t addr;
  
  line = [self getLine:row];
  sscanf([line UTF8String]+2, "%X", &addr);
  return addr;
}


- (NSView *)tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tc row:(NSInteger)row {
  NSString *line;
  
  uint32_t addr;
  BOOL hasBrkpt;
  id result;
  
  if ([simProxy simulatorState] != MOSSimulatorStatePaused) {
    line = @"";
    result = [tv makeViewWithIdentifier:@"normalView" owner:self];
    [[result textField] setStringValue:line];
    [[result imageView] setHidden:YES];
  } else {
    addr = [self getAddressForLine:row];
    hasBrkpt = [breakpoints containsObject:[NSNumber numberWithUnsignedInt:addr]];
    line = [self getLine:row];
    if ([line characterAtIndex:0] != '>')
      result = [tv makeViewWithIdentifier:@"normalView" owner:self];
    else
      result = [tv makeViewWithIdentifier:@"pcmarkedView" owner:self];
    [[result imageView] setHidden:!hasBrkpt];
    [[result textField] setFont:[self defaultMonospacedFont]];
    [[result textField] setStringValue:[line substringFromIndex:1]];
  }
  
  return result;
}


@end
