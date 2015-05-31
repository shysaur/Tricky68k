//
//  MOSJobStatusManager.m
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 11/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import "MOSJobStatusManager.h"


NSString * const MOSJobStatus                   = @"MOSJobStatus";
NSString * const MOSJobAssociatedFile           = @"MOSJobAssociatedFile";
NSString * const MOSJobStartDate                = @"MOSJobStartDate";
NSString * const MOSJobVisibleDescription       = @"MOSJobVisibleDescription";
NSString * const MOSJobEvents                   = @"privateMOSJobEvents";

NSString * const MOSJobStatusWorking            = @"MOSJobStatusWorking";
NSString * const MOSJobStatusSuccess            = @"MOSJobStatusSuccess";
NSString * const MOSJobStatusSuccessWithWarning = @"MOSJobStatusSuccessWithWarning";
NSString * const MOSJobStatusFailure            = @"MOSJobStatusFailure";

NSString * const MOSJobEventText                = @"MOSJobVisibleDescription";
NSString * const MOSJobEventAssociatedLine      = @"MOSJobEventAssociatedLine";
NSString * const MOSJobEventType                = @"MOSJobStatus";

NSString * const MOSJobEventTypeMessage         = @"MOSJobInfoMessage";
NSString * const MOSJobEventTypeWarning         = @"MOSJobStatusSuccessWithWarning";
NSString * const MOSJobEventTypeError           = @"MOSJobStatusFailure";


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
  
  jobs = [[NSMutableDictionary alloc] init];
  idCounter = 0;
  
  return self;
}


- (NSUInteger)addJobWithInfo:(NSDictionary *)info {
  NSNumber *jobid;
  NSMutableDictionary *minfo;
  
  jobid = [NSNumber numberWithUnsignedInteger:idCounter++];
  
  minfo = [info mutableCopy];
  [minfo setObject:[NSMutableArray array] forKey:MOSJobEvents];
  [minfo setObject:MOSJobStatusWorking forKey:MOSJobStatus];
  [minfo setObject:[NSDate date] forKey:MOSJobStartDate];
  
  [jobs setObject:minfo forKey:jobid];
  
  [self willChangeValueForKey:@"jobList"];
  [self cacheJobList];
  [self didChangeValueForKey:@"jobList"];
  
  return [jobid integerValue];
}


- (void)finishJob:(NSUInteger)jobid withResult:(NSString *)jobres {
  NSMutableDictionary *dict;
  
  dict = [jobs objectForKey:[NSNumber numberWithUnsignedInteger:jobid]];
  if ([[dict objectForKey:MOSJobStatus] isEqual:MOSJobStatusWorking]) {
    [self willChangeValueForKey:@"jobList"];
    [dict setObject:jobres forKey:MOSJobStatus];
    [self didChangeValueForKey:@"jobList"];
  }
}


- (void)addEvent:(NSDictionary *)info toJob:(NSUInteger)jobid {
  NSMutableDictionary *dict;
  NSMutableArray *events;
  
  dict = [jobs objectForKey:[NSNumber numberWithUnsignedInteger:jobid]];
  if ([[dict objectForKey:MOSJobStatus] isEqual:MOSJobStatusWorking]) {
    events = [dict objectForKey:MOSJobEvents];
    
    [self willChangeValueForKey:@"jobList"];
    [events addObject:info];
    [self didChangeValueForKey:@"jobList"];
  }
}


- (void)clearJobList {
  NSDictionary *oldJobs;
  NSNumber *jobid;
  NSMutableDictionary *job;
  
  oldJobs = [jobs copy];
  for (jobid in oldJobs) {
    job = [jobs objectForKey:jobid];
    if (![[job objectForKey:MOSJobStatus] isEqual:MOSJobStatusWorking]) {
      [jobs removeObjectForKey:jobid];
    }
  }
  
  [self willChangeValueForKey:@"jobList"];
  [self cacheJobList];
  [self didChangeValueForKey:@"jobList"];
}


- (void)cacheJobList {
  NSArray *keys;
  NSMutableArray *values;
  NSNumber *obj;
  
  keys = [jobs keysSortedByValueUsingComparator:^(id obj1, id obj2) {
    NSDate *date1;
    NSDate *date2;
    
    date1 = [obj1 objectForKey:MOSJobStartDate];
    date2 = [obj2 objectForKey:MOSJobStartDate];
    return [date2 compare:date1];
  }];
  
  values = [NSMutableArray array];
  for (obj in keys) {
    [values addObject:[jobs objectForKey:obj]];
  }
  cachedJobList = [values copy];
}


- (NSArray*)jobList {
  return cachedJobList;
}


- (NSArray*)eventListForJob:(NSUInteger)jobid {
  NSMutableArray *eventList;
  NSMutableDictionary *job;
  
  job = [jobs objectForKey:[NSNumber numberWithUnsignedInteger:jobid]];
  eventList = [job objectForKey:MOSJobEvents];
  return [eventList copy];
}


@end
