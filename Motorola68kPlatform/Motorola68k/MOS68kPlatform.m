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
#import "MOS68kAssemblerPrefViewController.h"
#import "MOS68kSimulatorPrefViewController.h"


@implementation MOS68kPlatform


+ (void)load {
  NSUserDefaults *ud;
  
  ud = [NSUserDefaults standardUserDefaults];
  [ud registerDefaults:@{
    @"FixedEntryPoint": @YES,
    @"UseAssemblyTimeOptimization": @NO
  }];
}


- (Class)executableClass {
  return [MOSFileBackedExecutable class];
}


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
  return [[self bundle] URLForResource:fn withExtension:nil];
}


- (NSViewController *)assemblerPreferencesViewController {
  return [[MOS68kAssemblerPrefViewController alloc] init];
}


- (NSViewController *)simulatorPreferencesViewController {
  return [[MOS68kSimulatorPrefViewController alloc] init];
}


- (MOSAssemblageOptions)currentAssemblageOptions
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  MOSAssemblageOptions opts;
  
  opts = [ud boolForKey:@"FixedEntryPoint"] ?
    MOS68kAssemblageOptionEntryPointFixed : MOS68kAssemblageOptionEntryPointSymbolic;
  opts |= [ud boolForKey:@"UseAssemblyTimeOptimization"] ?
    MOS68kAssemblageOptionOptimizationOn : MOS68kAssemblageOptionOptimizationOff;
  
  return opts;
}


@end
