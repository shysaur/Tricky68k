//
//  MOSDocument.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 18/03/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSDocument.h"


static void *TouchBarVisibilityContext = &TouchBarVisibilityContext;


@interface MOSDocument ()

@property (nonatomic) NSTouchBar *touchBar;

@end


@implementation MOSDocument


#pragma mark - Transient Documents


- (instancetype)init {
  self = [super init];
  _transient = NO;
  return self;
}


- (void)updateChangeCount:(NSDocumentChangeType)change {
  [self setTransient:NO];
  [super updateChangeCount:change];
}


#pragma mark - Touch Bar


- (void)windowControllerDidLoadNib:(NSWindowController *)wc {
  NSWindow *w;
  NSNotificationCenter *nc;
  
  [super windowControllerDidLoadNib:wc];
  
  if ([wc respondsToSelector:@selector(setTouchBar:)]) {
    self.touchBar = [self makeTouchBar];
    if (self.touchBar) {
      [wc setTouchBar:self.touchBar];
    
      w = [wc window];
      nc = [NSNotificationCenter defaultCenter];
      [nc addObserver:self selector:@selector(refreshTouchBar:)
        name:NSWindowDidUpdateNotification object:w];
      
      [self.touchBar addObserver:self forKeyPath:@"visible"
        options:0 context:TouchBarVisibilityContext];
    }
  }
}


- (NSTouchBar *)makeTouchBar {
  return nil;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
  change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  if (context == TouchBarVisibilityContext) {
    [self refreshTouchBar:nil];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object
      change:change context:context];
  }
}


- (void)refreshTouchBar:(NSNotification *)n {
  NSString *itmid;
  NSArray <NSString *> *itmids;
  NSTouchBarItem *tbi;
  NSControl <NSValidatedUserInterfaceItem> *view;
  id target;
  
  if (!self.touchBar.isVisible)
    return;
  
  itmids = self.touchBar.itemIdentifiers;
  for (itmid in itmids) {
    tbi = [self.touchBar itemForIdentifier:itmid];
    if (![tbi isKindOfClass:[NSCustomTouchBarItem class]])
      continue;
    
    view = (NSControl <NSValidatedUserInterfaceItem> *)[tbi view];
    if (![view isKindOfClass:[NSControl class]])
      continue;
    if (![view respondsToSelector:@selector(action)])
      continue;
    if (![view respondsToSelector:@selector(target)])
      continue;
    
    target = [view target];
    if (!target)
      continue;
  
    if ([target respondsToSelector:@selector(validateUserInterfaceItem:)]) {
      BOOL res = [target validateUserInterfaceItem:view];
      [view setEnabled:res];
    }
  }
}


- (void)dealloc {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
  [self.touchBar removeObserver:self
    forKeyPath:@"visible" context:TouchBarVisibilityContext];
}


#pragma mark - Error Presentation


- (void)presentDocumentModalError:(NSError *)e
{
  [self presentError:e modalForWindow:[self windowForSheet]
    delegate:nil didPresentSelector:nil contextInfo:NULL];
}


@end
