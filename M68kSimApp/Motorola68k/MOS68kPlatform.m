//
//  MOS68kPlatform.m
//  Tricky68k
//
//  Created by Daniele Cattaneo on 02/01/17.
//  Copyright © 2017 Daniele Cattaneo. All rights reserved.
//

#import "MOS68kPlatform.h"
#import "MOS68kAssembler.h"
#import "MOS68kSimulator.h"
#import "MOS68kSimulatorPresentation.h"


@implementation MOS68kPlatform


- (Class)assemblerClass {
  return [MOS68kAssembler class];
}


- (Class)simulatorClass {
  return [MOS68kSimulator class];
}


- (Class)presentationClass {
  return [MOS68kSimulatorPresentation class];
}


- (NSString *)localizedName {
  return @"Motorola 68000";
}


- (NSString *)syntaxDefinitionName {
  return @"ASM-m68k";
}


- (NSURL *)editorTemplate {
  return [[self bundle] URLForResource:@"VasmTemplate" withExtension:@"s"];
}


- (NSArray<NSDictionary *> *)examplesList {
  NSBundle *bundle;
  NSURL *examplesDirPlist;
  
  bundle = [self bundle];
  examplesDirPlist = [bundle URLForResource:@"ExamplesList" withExtension:@"plist"];
  return [NSArray arrayWithContentsOfURL:examplesDirPlist];
}


- (NSURL *)URLForExampleFile:(NSString *)fn {
  NSString *ext = [fn pathExtension];
  NSString *name = [fn stringByDeletingPathExtension];
  return [[self bundle] URLForResource:fn withExtension:nil];
}


@end
