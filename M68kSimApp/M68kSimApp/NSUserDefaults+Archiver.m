//
//  NSUserDefaults+Archiver.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 23/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "NSUserDefaults+Archiver.h"


@implementation NSUserDefaults (Archiver)


- (id)unarchivedObjectForKey:(NSString*)key {
  NSData *archivedObj;
  
  archivedObj = [self dataForKey:key];
  if (!archivedObj) return nil;
  return [NSUnarchiver unarchiveObjectWithData:archivedObj];
}


- (id)unarchivedObjectForKey:(NSString*)key class:(Class)chk {
  id obj;
  
  obj = [self unarchivedObjectForKey:key];
  if (!obj || ![obj isKindOfClass:chk]) {
    [self removeObjectForKey:key];
    obj = [self unarchivedObjectForKey:key];
    if (obj && [obj isKindOfClass:chk])
      return obj;
    else
      return nil;
  }
  return obj;
}


- (void)setObjectByArchiving:(id)obj forKey:(NSString*)key {
  NSData *archivedObj;
  
  archivedObj = [NSArchiver archivedDataWithRootObject:obj];
  [self setObject:archivedObj forKey:key];
}


@end
