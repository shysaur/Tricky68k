//
//  MOSSimulatorPresentation.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 10/12/15.
//  Copyright © 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


@class MOSSimulator;


@interface MOSSimulatorPresentation : NSObject

- (instancetype)initWithSimulator:(MOSSimulator *)s;

+ (NSString *)statusRegisterInterpretationPlaceholder;

- (NSNumber *)programCounter;
- (NSNumber *)stackPointer;
- (NSNumber *)statusRegister;
- (NSString *)statusRegisterInterpretation;
- (NSArray *)registerFileInterpretation;

@end
