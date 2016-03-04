//
//  MOSListingDictionary.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 04/03/16.
//  Copyright © 2016 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MOSListingDictionary : NSObject

- (instancetype)initWithListingFile:(NSURL *)f error:(NSError **)e;

- (NSNumber *)addressForSourceLine:(NSUInteger)l;
- (NSUInteger)sourceLineForAddress:(NSNumber *)n;

@end
