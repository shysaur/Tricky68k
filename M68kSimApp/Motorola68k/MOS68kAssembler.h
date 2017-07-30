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


@interface MOS68kAssembler : MOSAssembler <MOSMonitoredTaskDelegate> {
  NSMutableArray *sections;
  BOOL gotWarnings;
  BOOL linking;
  MOS68kListingDictionary *listingDict;
}

@property (nonatomic) BOOL produceListingDictionary;

@end
