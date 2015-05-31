//
//  MOSSimulatorSubviewDelegate.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 17/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>


@interface MOSSimulatorSubviewDelegate : NSObject {
  NSFont *viewFont;
  NSData *oldArchivedFont;
}

- (NSFont*)defaultMonospacedFont;
- (void)defaultMonospacedFontHasChanged; /* override */

@end
