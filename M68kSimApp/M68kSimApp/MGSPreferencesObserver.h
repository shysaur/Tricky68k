//
//  MGSTemporaryPreferencesObserver.h
//  Fragaria
//
//  Created by Jim Derry on 2/27/15.
//
//

#import <Cocoa/Cocoa.h>

@class MGSFragaria;


/** This internal class observes the changes to Fragaria's standard preference
 * panels and applies these changes to its instance of Fragaria. */

@interface MGSPreferencesObserver : NSObject


/** Designated initializer.
 * @param fragaria The fragaria class controlled by the new instance. */
- (instancetype)initWithFragaria:(MGSFragariaView *)fragaria;


@end
