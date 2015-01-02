//
//  MOSSimDisasmDataSource.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 01/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimDisasmDataSource.h"
#import "MOSSimulatorProxy.h"


@implementation MOSSimDisasmDataSource


- init {
  NSUserDefaults *ud;
  
  self = [super init];
  
  ud = [NSUserDefaults standardUserDefaults];
  maxLines = [ud integerForKey:@"disassemblyLines"];
  if (maxLines < 25) maxLines = 1501;
  maxLines |= 1; /* always odd */
  
  return self;
}


- (void)setSimulatorProxy:(MOSSimulatorProxy*)sp {
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorRunning"];
  } @finally {}
  simProxy = sp;
  [simProxy addObserver:self forKeyPath:@"simulatorRunning" options:0 context:NULL];
  [self refreshSimulatorData];
}


- (void)dealloc {
  @try {
    [simProxy removeObserver:self forKeyPath:@"simulatorRunning"];
  } @finally {}
}


- (void)observeValueForKeyPath:(NSString*)keyPath    ofObject:(id)object
                        change:(NSDictionary*)change context:(void*)context {
  if (![simProxy isSimulatorRunning])
    [self refreshSimulatorData];
}


- (void)refreshSimulatorData {
  NSDictionary *regs;
  
  regs = [simProxy registerDump];
  centerAddr = (uint32_t)[[regs objectForKey:MOS68kRegisterPC] unsignedLongValue];
  lineCache = [[simProxy disassemble:1 instructionsFromLocation:centerAddr] mutableCopy];
  cacheStart = (maxLines - 1) / 2;
  addrCacheStart = addrCacheEnd = centerAddr;
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


- (NSView *)tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tc row:(NSInteger)row {
  NSString *line;
  NSArray *add;
  NSMutableArray *newcache;
  NSInteger linestodo;
  id result;
  
  if ([simProxy simulatorState] != MOSSimulatorStatePaused) {
    line = @"";
  } else {
    if (row < cacheStart) {
      linestodo = row - cacheStart;
      add = [simProxy disassemble:(int)linestodo instructionsFromLocation:addrCacheStart];
      newcache = [add mutableCopy];
      [newcache addObjectsFromArray:lineCache];
      lineCache = newcache;
      cacheStart = row;
      [self updateCacheStartAddress];
    } else if (row >= cacheStart + [lineCache count]) {
      linestodo = row - (cacheStart + [lineCache count]) + 1;
      add = [simProxy disassemble:(int)linestodo+1 instructionsFromLocation:addrCacheEnd];
      newcache = [add mutableCopy];
      [newcache removeObjectAtIndex:0];
      [lineCache addObjectsFromArray:newcache];
      [self updateCacheEndAddress];
    } else
      linestodo = 0;
    
    line = [lineCache objectAtIndex:row - cacheStart];
  }
  result = [tv makeViewWithIdentifier:@"normalView" owner:self];
  [[result textField] setStringValue:line];
  return result;
}


@end
