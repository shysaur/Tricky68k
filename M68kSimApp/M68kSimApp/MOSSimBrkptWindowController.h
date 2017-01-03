//
//  MOSSimBrkptWindowController.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 30/09/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MOSSimBrkptWindowController : NSWindowController {
  NSWindow *modalWindow;
  NSArray *breakpts;
  NSArray *symbolLocator;
  NSDictionary *symbolTable;
  NSArray *sortDesc;
  IBOutlet NSArrayController *bptsController;
  IBOutlet NSSegmentedControl *addRemoveButtons;
}
  
- (instancetype)init;

- (void)beginSheetModalForWindow:(NSWindow *)p
               completionHandler:(void (^)(NSModalResponse result))handler;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)addOrRemove:(id)sender;

- (void)setBreakpointsFromSet:(NSSet*)b;
- (void)setDisplayedBreakpoints:(NSArray *)b;
- (NSArray *)displayedBreakpoints;

- (void)setSymbolTable:(NSDictionary*)st;

@end
