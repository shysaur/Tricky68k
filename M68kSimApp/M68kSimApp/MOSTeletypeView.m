//
//  MOSTeletypeView.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 07/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSTeletypeView.h"
#import "MOSTeletypeViewDelegate.h"


@implementation MOSTeletypeView


- (void)insertText:(id)aString {
  MOSTeletypeViewDelegate *d;
  
  d = [self delegate];
  [d sendString:aString];
}


@end
