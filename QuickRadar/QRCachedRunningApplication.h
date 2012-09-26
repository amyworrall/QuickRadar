//
//  QRCachedRunningApplication.h
//  RunningApps
//
//  Created by Balázs Faludi on 16.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QRCachedRunningApplication : NSObject <NSCoding>

@property (nonatomic, readonly) NSString *unlocalizedName;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *build;
@property (nonatomic, readonly) NSString *versionAndBuild;
@property (nonatomic, readonly) NSImage *icon;

- (id)initWithRunningApplication:(NSRunningApplication *)app;
- (NSArray *)findCrashReports;
- (BOOL)didCrashRecently;
- (NSString *)guessCategory;

@end
