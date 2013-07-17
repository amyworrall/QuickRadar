//
//  QRSubmissionService.m
//  QuickRadar
//
//  Created by Amy Worrall on 26/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRSubmissionService.h"

NSString * const QRWordpressSubmissionServiceIdentifier = @"QRWordpressSubmissionServiceIdentifier";
NSString * const QRRadarSubmissionServiceIdentifier = @"QRRadarSubmissionServiceIdentifier";
NSString * const QROpenRadarSubmissionServiceIdentifier = @"QROpenRadarSubmissionServiceIdentifier";
NSString * const QRTwitterSubmissionServiceIdentifier = @"QRTwitterSubmissionServiceIdentifier";

static NSMutableDictionary *_services;

@implementation QRSubmissionService

@synthesize radar = _radar;

+ (NSDictionary *)services
{
	return [NSDictionary dictionaryWithDictionary:_services];
}

+ (BOOL)requireCheckBox;
{
	return YES;
}

+ (NSDictionary *)checkBoxNames;
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	NSDictionary *services = [QRSubmissionService services];
	
	for (NSString *serviceID in services)
	{
		Class serviceClass = services[serviceID];
		
		if (![serviceClass isAvailable])
		{
			continue;
		}
		
		if ([serviceClass checkBoxString].length == 0)
		{
			continue;
		}
		
		dict[serviceID] = [serviceClass checkBoxString];
	}
	
	return [NSDictionary dictionaryWithDictionary:dict];
}

+ (void)registerService:(Class)service
{
	@autoreleasepool 
	{
		if (!_services)
		{
			_services = [NSMutableDictionary dictionary];
		}
		
		NSString *identifier = [service identifier];
		
		_services[identifier] = service;
		
	}
}

/** The following are all things subclasses should override **/

+ (NSString*)identifier
{
    return nil;
}

+ (NSString*)name
{
    return nil;
}

+ (NSSet*)hardDependencies
{
	return [NSSet set];
}

+ (NSSet*)softDependencies
{
	return [NSSet set];
}

+ (BOOL)supportedOnMac
{
    return NO;
}

+ (BOOL)supportedOniOS
{
    return NO;
}

+ (NSString*)macSettingsViewControllerClassName
{
    return nil;
}

+ (NSString*)iosSettingsViewControllerClassName
{
    return nil;
}

+ (id)settingsIconPlatformAppropriateImage
{
    return nil;
}

+ (NSString *)checkBoxString
{
	return nil;
}

+ (BOOL)isAvailable
{
	return YES;
}

- (SubmissionStatus)submissionStatus
{
    return submissionStatusNotStarted;
}

- (CGFloat)progress
{
    return 0.0f;
}

- (NSString *)statusText
{
    return nil;
}

- (void)submitAsyncWithProgressBlock:(void(^)())progressBlock completionBlock:(void(^)(BOOL success, NSError *error))completionBlock
{
    
}

@end
