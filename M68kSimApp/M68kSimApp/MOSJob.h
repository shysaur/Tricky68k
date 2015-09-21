//
//  MOSJobStatus.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 21/09/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


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


@interface MOSJob : NSObject {
  NSArray *eventList;
}

@property NSString *status;
@property NSURL *associatedFile;
@property NSDate *startDate;
@property NSString *visibleDescription;

- (NSArray *)events;
- (void)addEvent:(NSDictionary *)info;

@end
