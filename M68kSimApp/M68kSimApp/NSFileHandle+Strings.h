//
//  NSFileHandle+Strings.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 30/12/14.
//  Copyright (c) 2014 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileHandle (Strings)

- (void)writeString:(NSString*)str;
- (NSString*)readLine;

@end
