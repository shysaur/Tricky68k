//
//  MOSPlatformManager.h
//  Tricky68k
//
//  Created by Daniele Cattaneo on 02/01/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>


@class MOSPlatform;


@interface MOSPlatformManager : NSObject {
  NSArray<MOSPlatform *> *platforms;
}

+ (MOSPlatformManager *)sharedManager;

- (BOOL)loadPlatformsWithError:(NSError **)err;
- (MOSPlatform *)defaultPlatform;

@end
