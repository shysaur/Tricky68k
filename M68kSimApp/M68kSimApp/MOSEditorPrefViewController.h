//
//  MOSEditorPrefViewController.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 15/03/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>
#import <FragariaDefaultsCoordinator/FragariaDefaultsCoordinator.h>


@interface MOSEditorPrefViewController : NSViewController {
  NSFont *editorFont;
}

@property (nonatomic) IBOutlet NSUserDefaultsController *userDefaultsController;
@property (nonatomic) IBOutlet NSObjectController *colorSchemeController;
@property (nonatomic) IBOutlet MGSColourSchemeTableViewDataSource *colourSchemeTableViewDs;

@end
