//
//  MOSPlatform.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 11/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MOSAssembler.h"


@interface MOSPlatform : NSObject

@property (readonly) NSBundle *bundle;

@property (readonly) Class executableClass;
@property (readonly) Class assemblerClass;
@property (readonly) Class simulatorClass;
@property (readonly) Class presentationClass;
@property (readonly) NSString *localizedName;

@property (readonly) NSString *syntaxDefinitionName;
@property (readonly) NSURL *editorTemplate;

@property (readonly) NSArray<NSDictionary *> *examplesList;
- (NSURL *)URLForExampleFile:(NSString *)fn;

- (NSViewController *)assemblerPreferencesViewController;
- (NSViewController *)simulatorPreferencesViewController;

- (MOSAssemblageOptions)currentAssemblageOptions;

@end
