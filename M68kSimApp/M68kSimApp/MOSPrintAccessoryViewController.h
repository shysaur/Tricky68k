//
//  MOSPrintAccessoryViewController.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 12/03/16.
//  Copyright © 2016 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString * const MOSDefaultsPrintFont;


@interface MOSPrintAccessoryViewController : NSViewController <NSPrintPanelAccessorizing> {
  NSFont *baseFont;
}

@property (nonatomic) NSFont *textFont;
- (IBAction)changeTextFont:(id)sender;

- (NSArray *)localizedSummaryItems;
- (NSSet *)keyPathsForValuesAffectingPreview;

@end
