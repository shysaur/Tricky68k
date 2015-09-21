//
//  MOSJobStatusManager.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 11/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSJobStatusManager.h"
#import "MOSJob.h"


@implementation MOSJobStatusManager


+ (MOSJobStatusManager *)sharedJobStatusManger {
  static MOSJobStatusManager *sharedSm;
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    sharedSm = [[MOSJobStatusManager _alloc] _init];
  });
  return sharedSm;
}


+ (instancetype)allocWithZone:(struct _NSZone *)zone {
  return [MOSJobStatusManager sharedJobStatusManger];
}


+ (instancetype)alloc {
  return [MOSJobStatusManager sharedJobStatusManger];
}


- init {
  return self;
}


+ _alloc {
  return [super allocWithZone:nil];
}


- _init {
  self = [super init];
  jobs = [[NSMutableSet alloc] init];
  return self;
}


- (void)addJob:(MOSJob *)job {
  [jobs addObject:job];
  [self cacheJobList];
}


- (void)clearJobList {
  NSMutableSet *newjobs;
  MOSJob *job;
  
  newjobs = [[NSMutableSet alloc] init];
  for (job in jobs) {
    if ([[job status] isEqual:MOSJobStatusWorking]) {
      [newjobs addObject:job];
    }
  }
  jobs = newjobs;
  
  [self cacheJobList];
}


- (void)cacheJobList {
  NSSortDescriptor *desc;
  NSArray *list;
  
  desc = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:NO];
  list = [jobs sortedArrayUsingDescriptors:@[desc]];
  [self setJobList:list];
}


- (NSArray*)jobList {
  return cachedJobList;
}


- (void)setJobList:(NSArray*)jl {
  cachedJobList = jl;
}


@end
