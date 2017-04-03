//
//  MOSSimulatorSubviewDelegate.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 17/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSSimulatorSubviewDelegate.h"
#import "NSUserDefaults+Archiver.h"


static void *DebuggerTextFontDefaultContext = &DebuggerTextFontDefaultContext;


@implementation MOSSimulatorSubviewDelegate


+ (void)load {
  NSFont *defaultTextFont;
  NSData *archivedFont;
  NSUserDefaults *ud;
  
  ud = [NSUserDefaults standardUserDefaults];
  defaultTextFont = [NSFont fontWithName:@"Menlo" size:11.0];
  archivedFont = [NSArchiver archivedDataWithRootObject:defaultTextFont];
  [ud registerDefaults:@{@"DebuggerTextFont": archivedFont}];
}


- (instancetype)init {
  NSUserDefaults *ud;
  
  self = [super init];
  
  ud = [NSUserDefaults standardUserDefaults];
  [ud addObserver:self forKeyPath:@"DebuggerTextFont"
    options:NSKeyValueObservingOptionInitial
    context:DebuggerTextFontDefaultContext];
  return self;
}


- (void)dealloc {
  NSUserDefaults *ud;

  ud = [NSUserDefaults standardUserDefaults];
  [ud removeObserver:self forKeyPath:@"DebuggerTextFont"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
  change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
  if (context == DebuggerTextFontDefaultContext) {
    [self reloadDefaultMonospacedFont];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}


- (void)reloadDefaultMonospacedFont {
  NSUserDefaults *ud;
  NSFont *f;
  
  ud = [NSUserDefaults standardUserDefaults];
  f = [ud unarchivedObjectForKey:@"DebuggerTextFont" class:[NSFont class]];
  [self setDefaultMonospacedFont:f];
}


@end
