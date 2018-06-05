//
//  MOSSimBrkptWindowController.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 30/09/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSSimBrkptWindowController.h"
#import "MOSUndoableMutableBreakpoint.h"


static void *CanRemoveContext = &CanRemoveContext;


@implementation MOSSimBrkptWindowController


- (instancetype)init {
  self = [super initWithWindowNibName:@"MOSSimBrkptWindow"];
  undoManager = [[NSUndoManager alloc] init];
  return self;
}


- (void)windowDidLoad {
  [self setSortDescriptors:@[
      [NSSortDescriptor sortDescriptorWithKey:@"address" ascending:YES]
    ]];
  [bptsController addObserver:self forKeyPath:@"canRemove"
    options:NSKeyValueObservingOptionInitial context:CanRemoveContext];
}


- (NSUndoManager *)undoManager
{
  return undoManager;
}


- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
  return self.undoManager;
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
      [self add:sender];
      break;
    case 1:
      [self remove:sender];
      break;
  }
}


- (void)add:(id)sender
{
  NSArray *oldbps = [self.displayedBreakpoints copy];
  [[undoManager prepareWithInvocationTarget:self] setDisplayedBreakpoints:oldbps];
  [undoManager setActionName:NSLocalizedString(@"Add", @"Add breakpoint undo label")];
  
  MOSUndoableMutableBreakpoint *bp;
  bp = [[MOSUndoableMutableBreakpoint alloc] initWithAddress:0
        symbolTable:symbolTable symbolLocator:symbolLocator];
  [bp setUndoManager:self.undoManager];
  [bptsController addObject:bp];
}


- (void)remove:(id)sender
{
  NSArray *oldbps = [self.displayedBreakpoints copy];
  [[undoManager prepareWithInvocationTarget:self] setDisplayedBreakpoints:oldbps];
  [undoManager setActionName:NSLocalizedString(@"Remove", @"Remove breakpoint undo label")];
  
  [bptsController remove:sender];
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
  MOSUndoableMutableBreakpoint *bp;
  
  conv = [[NSMutableArray alloc] init];
  for (n in b) {
    bp = [[MOSUndoableMutableBreakpoint alloc] initWithAddress:[n unsignedIntValue]
         symbolTable:symbolTable symbolLocator:symbolLocator];
    [bp setUndoManager:self.undoManager];
    [conv addObject:bp];
  }
  [self setDisplayedBreakpoints:[conv copy]];
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
