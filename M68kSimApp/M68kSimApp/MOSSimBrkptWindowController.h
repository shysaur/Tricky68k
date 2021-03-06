//
//  MOSSimBrkptWindowController.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 30/09/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MOSSimBrkptWindowController : NSWindowController <NSUserInterfaceValidations> {
  NSWindow *modalWindow;
  NSArray *symbolLocator;
  NSDictionary *symbolTable;
  NSUndoManager *undoManager;
  IBOutlet NSArrayController *bptsController;
  IBOutlet NSSegmentedControl *addRemoveButtons;
}
  
- (instancetype)init;

- (void)beginSheetModalForWindow:(NSWindow *)p
               completionHandler:(void (^)(NSModalResponse result))handler;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)addOrRemove:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)remove:(id)sender;

- (void)setBreakpointsFromSet:(NSSet*)b;
@property NSArray *displayedBreakpoints;

@property NSArray *sortDescriptors;

- (void)setSymbolTable:(NSDictionary*)st;

@end
