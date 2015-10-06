//
//  MOSError.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 15/06/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MOSError : NSError

+ (void)setUserInfoValueDictionary:(NSDictionary *)dict forDomain:(NSString *)d;

+ (instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code;

- (instancetype)initWithDomain:(NSString *)domain code:(NSInteger)code
  userInfo:(NSDictionary *)dict;

@end
