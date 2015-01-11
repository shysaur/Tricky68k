//
//  MOSJobWindowController.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 11/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MOSJobWindowController : NSWindowController {
  IBOutlet NSTextField *fakeTitle;
}

- (IBAction)clearJobList:(id)sender;

@end
