//
//  MOSJobStatus.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 21/09/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const MOSJobStatusWorking;
extern NSString * const MOSJobStatusSuccess;
extern NSString * const MOSJobStatusSuccessWithWarning;
extern NSString * const MOSJobStatusFailure;

extern NSString * const MOSJobEventText;
extern NSString * const MOSJobEventAssociatedLine;
extern NSString * const MOSJobEventType;
extern NSString * const MOSJobEventTypeMessage;
extern NSString * const MOSJobEventTypeWarning;
extern NSString * const MOSJobEventTypeError;


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
