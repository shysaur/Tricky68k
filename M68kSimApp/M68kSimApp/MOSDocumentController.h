//
//  MOSDocumentController.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 18/03/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>


@interface MOSDocumentController : NSDocumentController {
  NSLock *transientClose;
}

@end
