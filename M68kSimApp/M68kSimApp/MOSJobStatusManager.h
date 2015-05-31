//
//  MOSJobStatusManager.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 11/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Foundation/Foundation.h>


NSString * const MOSJobStatus;
NSString * const MOSJobAssociatedFile;
NSString * const MOSJobStartDate;
NSString * const MOSJobVisibleDescription;

NSString * const MOSJobStatusWorking;
NSString * const MOSJobStatusSuccess;
NSString * const MOSJobStatusSuccessWithWarning;
NSString * const MOSJobStatusFailure;

NSString * const MOSJobEventText;
NSString * const MOSJobEventAssociatedLine;
NSString * const MOSJobEventType;
NSString * const MOSJobEventTypeMessage;
NSString * const MOSJobEventTypeWarning;
NSString * const MOSJobEventTypeError;


@interface MOSJobStatusManager : NSObject {
  NSUInteger idCounter;
  NSMutableDictionary *jobs;
  NSArray *cachedJobList;
}

+ (MOSJobStatusManager *)sharedJobStatusManger;

- (NSUInteger)addJobWithInfo:(NSDictionary *)info;
- (void)finishJob:(NSUInteger)jobid withResult:(NSString *)jobres;
- (void)addEvent:(NSDictionary *)info toJob:(NSUInteger)jobid;

- (void)clearJobList;
- (NSArray*)jobList;
- (NSArray*)eventListForJob:(NSUInteger)jobid;

@end
