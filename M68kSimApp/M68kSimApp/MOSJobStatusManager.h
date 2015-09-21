//
//  MOSJobStatusManager.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 11/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Foundation/Foundation.h>


@class MOSJob;


@interface MOSJobStatusManager : NSObject {
  NSMutableSet *jobs;
  NSArray *cachedJobList;
}

+ (MOSJobStatusManager *)sharedJobStatusManger;

- (void)addJob:(MOSJob *)job;
- (void)clearJobList;
- (NSArray*)jobList;

@end
