//
//  MOSError.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 15/06/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import "MOSError.h"


static NSMutableDictionary *userInfoDataDict = nil;


@implementation MOSError


+ (void)setUserInfoValueDictionary:(NSDictionary *)dict forDomain:(NSString *)d {
  if (!userInfoDataDict) {
    userInfoDataDict = [[NSMutableDictionary alloc] init];
  }
  [userInfoDataDict setObject:dict forKey:d];
}


- (instancetype)initWithDomain:(NSString *)domain code:(NSInteger)code
  userInfo:(NSDictionary *)dict {
  NSDictionary *domaindict, *userinfo;
  NSMutableDictionary *tmp;
  
  domaindict = [userInfoDataDict objectForKey:domain];
  userinfo = [domaindict objectForKey:@(code)];
  if (!userinfo)
    userinfo = dict;
  else if (dict) {
    tmp = [userinfo mutableCopy];
    [tmp addEntriesFromDictionary:dict];
    userinfo = tmp;
  }
  
  return [super initWithDomain:domain code:code userInfo:userinfo];
}


@end
