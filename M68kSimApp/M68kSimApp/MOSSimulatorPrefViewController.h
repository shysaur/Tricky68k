//
//  MOSSimulatorPrefViewController.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 17/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>


@interface MOSSimulatorPrefViewController : NSViewController {
  NSFont *baseFont;
  NSMutableArray<NSViewController *> *childVcs;
}

- (IBAction)changeDebuggerFont:(id)sender;

@property (nonatomic) IBOutlet NSView *separatorView;
@property (nonatomic, weak) IBOutlet NSStackView *pluginPrefsView;

@end
