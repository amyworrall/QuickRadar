//
//  TestService.m
//  QuickRadar
//
//  Created by Amy Worrall on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TestService.h"

@implementation TestService


+ (void)load
{
	[QRSubmissionService registerService:self];
}

+ (NSSet *)hardDependencies
{
	return [NSSet setWithObject: QRRadarSubmissionServiceIdentifier ];
}

+ (NSString *)identifier
{
	return @"TestID";
}

+ (NSString *)name
{
	return @"WaitUntilAfterRadar";
}

+ (BOOL)supportedOnMac;
{
	return YES;
}

+ (BOOL)supportedOniOS;
{
	return NO;
}

+ (NSString*)macSettingsViewControllerClassName;
{
	return @"QRRadarSubmissionServicePreferencesViewController";
}

+ (NSString*)iosSettingsViewControllerClassName;
{
	return nil;
}

+ (id)settingsIconPlatformAppropriateImage;
{
	if (NSClassFromString(@"NSImage"))
	{
		return [NSImage imageNamed:@"MenubarTemplate"];
	}
	return nil;
}

- (CGFloat)progress
{
	return 1.0;
}

- (SubmissionStatus)submissionStatus
{
	return submissionStatusNotStarted;
}


- (void)submitAsyncWithProgressBlock:(void (^)())progressBlock completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
	NSLog(@"After radar?");
	completionBlock(YES, nil);
}
@end
