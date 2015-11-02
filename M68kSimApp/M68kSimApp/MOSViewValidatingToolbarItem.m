//
//  MOSViewValidatingToolbarItem.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 01/11/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSViewValidatingToolbarItem.h"


@implementation MOSViewValidatingToolbarItem


- (void)validate {
  id target;
  NSControl <NSValidatedUserInterfaceItem> *view;
  BOOL res;
  
  view = (NSControl <NSValidatedUserInterfaceItem> *)[self view];
  if (!view) {
    [super validate];
    return;
  }
  
  if (![[self view] isKindOfClass:[NSControl class]])
    return;
  if (![view respondsToSelector:@selector(action)])
    return;
  if (![view respondsToSelector:@selector(tag)])
    return;
  
  target = [view target];
  if (!target)
    return;
  
  if ([target respondsToSelector:@selector(validateUserInterfaceItem:)]) {
    res = [target validateUserInterfaceItem:view];
    [view setEnabled:res];
    [self setEnabled:res];
  }
}


@end
