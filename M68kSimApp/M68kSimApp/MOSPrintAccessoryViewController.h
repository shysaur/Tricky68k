//
//  MOSPrintAccessoryViewController.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 12/03/16.
//  Copyright © 2016 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Fragaria/Fragaria.h>
#import "MOSColourSchemeListController.h"


extern NSString * const MOSDefaultsPrintFont;
extern NSString * const MOSDefaultsPrintColorScheme;


@interface MOSPrintAccessoryViewController : NSViewController <NSPrintPanelAccessorizing> {
  NSFont *baseFont;
}

@property (nonatomic) IBOutlet MOSColourSchemeListController *colourSchemeListController;
@property (nonatomic) MGSColourScheme *colorScheme;

@property (nonatomic) NSFont *textFont;
- (IBAction)changeTextFont:(id)sender;

- (NSArray *)localizedSummaryItems;
- (NSSet *)keyPathsForValuesAffectingPreview;

@end
