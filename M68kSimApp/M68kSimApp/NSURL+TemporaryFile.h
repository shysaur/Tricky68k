//
//  NSURL+TemporaryFile.h
//  M68kSimApp
//
//  Created by Daniele Cattaneo on 10/01/15.
//  Copyright (c) 2015 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (TemporaryFile)

+ (instancetype)URLWithTemporaryFilePath;
+ (instancetype)URLWithTemporaryFilePathWithExtension:(NSString*)ext;

@end
