//
//  MOSPlatformSupport.h
//  MOSPlatformSupport
//
//  Created by Daniele Cattaneo on 02/01/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MOSPlatform.h"
#import "MOSExecutable.h"
#import "MOSFileBackedExecutable.h"
#import "MOSAssembler.h"
#import "MOSListingDictionary.h"
#import "MOSSimulator.h"
#import "MOSSimulatorPresentation.h"

#import "MOSJob.h"

#import "MOSNamedPipe.h"
#import "NSFileHandle+Strings.h"
#import "NSURL+TemporaryFile.h"
#import "NSScanner+Shorteners.h"
#import "NSUserDefaults+Archiver.h"
#import "MOSError.h"


#define MOSPlatformLocalized(text, desc) \
  [[NSBundle bundleForClass:[self class]] localizedStringForKey:text value:nil table:nil]


