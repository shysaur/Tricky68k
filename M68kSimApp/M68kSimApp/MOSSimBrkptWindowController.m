//
//  MOSSimBrkptWindowController.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 30/09/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimBrkptWindowController.h"
#import "MOSMutableBreakpoint.h"


static void *CanRemoveContext = &CanRemoveContext;


@implementation MOSSimBrkptWindowController


- (instancetype)init {
  self = [super initWithWindowNibName:@"MOSSimBrkptWindow"];
  return self;
}


- (void)windowDidLoad {
  [self setSortDescriptors:@[
      [NSSortDescriptor sortDescriptorWithKey:@"address" ascending:YES]
    ]];
  [bptsController addObserver:self forKeyPath:@"canRemove"
    options:NSKeyValueObservingOptionInitial context:CanRemoveContext];
}


- (void)setSortDescriptors:(NSArray*)sd {
  sortDesc = sd;
}


- (NSArray *)sortDescriptors {
  return sortDesc;
}


- (IBAction)cancel:(id)sender {
  [modalWindow endSheet:[self window] returnCode:NSModalResponseCancel];
  modalWindow = nil;
}


- (IBAction)ok:(id)sender {
  [modalWindow endSheet:[self window] returnCode:NSModalResponseOK];
  modalWindow = nil;
}


- (IBAction)addOrRemove:(id)sender {
  if (![sender isKindOfClass:[NSSegmentedControl class]])
    return;
  
  switch ([sender selectedSegment]) {
    case 0:
      [bptsController addObject:[[MOSMutableBreakpoint alloc] initWithAddress:0
        symbolTable:symbolTable symbolLocator:symbolLocator]];
      break;
    case 1:
      [bptsController remove:sender];
      break;
  }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context {
  if (context == CanRemoveContext) {
    [self updateAddRemoveButtons];
  }
}


- (void)updateAddRemoveButtons
{
  [addRemoveButtons setEnabled:[bptsController canRemove] forSegment:1];
  [addRemoveButtons setEnabled:YES forSegment:0];
}


- (void)beginSheetModalForWindow:(NSWindow *)p
               completionHandler:(void (^)(NSModalResponse result))handler {
  NSWindow *w;
  
  if (modalWindow)
    return;
  
  w = [self window];
  modalWindow = p;
  [p beginSheet:w completionHandler:handler];
}


- (void)setBreakpointsFromSet:(NSSet*)b {
  NSMutableArray *conv;
  NSNumber *n;
  MOSMutableBreakpoint *bp;
  
  conv = [[NSMutableArray alloc] init];
  for (n in b) {
    bp = [[MOSMutableBreakpoint alloc] initWithAddress:[n unsignedIntValue]
         symbolTable:symbolTable symbolLocator:symbolLocator];
    [conv addObject:bp];
  }
  [self setDisplayedBreakpoints:[conv copy]];
}


- (void)setDisplayedBreakpoints:(NSArray *)b {
  breakpts = b;
}


- (NSArray *)displayedBreakpoints {
  return breakpts;
}


- (void)setSymbolTable:(NSDictionary*)st {
  if (symbolTable != st) {
    symbolLocator = [[st allKeys] sortedArrayUsingSelector:@selector(compare:)];
    symbolTable = st;
  }
}


- (void)dealloc {
  [bptsController removeObserver:self forKeyPath:@"canRemove"];
}


@end
