//
//  MOSUndoableMutableBreakpoint.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/06/18.
//  Copyright © 2018 Daniele Cattaneo. All rights reserved.
//

#import "MOSMutableBreakpoint.h"


@interface MOSUndoableMutableBreakpoint : MOSMutableBreakpoint

@property (weak) NSUndoManager *undoManager;

@end
