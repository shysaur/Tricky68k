//
//  MOSUndoableMutableBreakpoint.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/06/18.
//  Copyright © 2018 Daniele Cattaneo. All rights reserved.
//

#import "MOSUndoableMutableBreakpoint.h"


@implementation MOSUndoableMutableBreakpoint


- (void)setAddress:(NSNumber *)a
{
  [[self.undoManager prepareWithInvocationTarget:self] setAddress:self.address];
  if (![self.undoManager isUndoing]) {
    [self.undoManager setActionName:NSLocalizedString(@"Change Address", @"Change breakpoint Address undo action label")];
  }
  [super setAddress:a];
}


- (void)setSymbolicLocation:(NSString *)str
{
  [[self.undoManager prepareWithInvocationTarget:self] setSymbolicLocation:self.symbolicLocation];
  if (![self.undoManager isUndoing]) {
    [self.undoManager setActionName:NSLocalizedString(@"Change Symbolic Location", @"Change breakpoint Symbolic Location undo action label")];
  }
  [super setSymbolicLocation:str];
}


@end
