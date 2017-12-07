//
//  MOSAssembler.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 09/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Foundation/Foundation.h>
#import "PlatformSupport.h"
#import "MOSMonitoredTask.h"


@class MOS68kListingDictionary;


typedef NS_OPTIONS(MOSAssemblageOptions, MOS68kAssemblageOptions) {
  MOS68kAssemblageOptionOptimizationOff = 0,
  MOS68kAssemblageOptionOptimizationOn = 1 << 16,
  MOS68kAssemblageOptionEntryPointFixed = 0,
  MOS68kAssemblageOptionEntryPointSymbolic = 1 << 17,
};


@interface MOS68kAssembler : MOSAssembler <MOSMonitoredTaskDelegate> {
  NSMutableArray *sections;
  BOOL gotWarnings;
  BOOL linking;
  MOS68kListingDictionary *listingDict;
}

@property (nonatomic) BOOL produceListingDictionary;

@end
