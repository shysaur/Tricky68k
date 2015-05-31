//
//  NSUserDefaults+Archiver.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 23/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. 
//

#import <Cocoa/Cocoa.h>


@interface NSUserDefaults (Archiver)

- (id)unarchivedObjectForKey:(NSString*)key;
- (id)unarchivedObjectForKey:(NSString*)key class:(Class)chk;
- (void)setObjectByArchiving:(id)obj forKey:(NSString*)key;

@end
