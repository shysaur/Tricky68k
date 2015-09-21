//
//  MOSJobStatus.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 21/09/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSJob.h"


NSString * const MOSJobStatusWorking            = @"MOSJobStatusWorking";
NSString * const MOSJobStatusSuccess            = @"MOSJobStatusSuccess";
NSString * const MOSJobStatusSuccessWithWarning = @"MOSJobStatusSuccessWithWarning";
NSString * const MOSJobStatusFailure            = @"MOSJobStatusFailure";

NSString * const MOSJobEventText                = @"visibleDescription";
NSString * const MOSJobEventAssociatedLine      = @"MOSJobEventAssociatedLine";
NSString * const MOSJobEventType                = @"status";

NSString * const MOSJobEventTypeMessage         = @"MOSJobInfoMessage";
NSString * const MOSJobEventTypeWarning         = @"MOSJobStatusSuccessWithWarning";
NSString * const MOSJobEventTypeError           = @"MOSJobStatusFailure";


@implementation MOSJob


- (id)init {
  self = [super init];
  _startDate = [NSDate date];
  _status = MOSJobStatusWorking;
  return self;
}


- (NSArray *)events {
  return eventList;
}


- (void)setEvents:(NSArray *)e {
  eventList = e;
}


- (void)addEvent:(NSDictionary *)info {
  NSMutableArray *tmp;
  
  if (eventList)
    tmp = [eventList mutableCopy];
  else
    tmp = [NSMutableArray array];
  [tmp addObject:info];
  [self setEvents:[tmp copy]];
}


@end
