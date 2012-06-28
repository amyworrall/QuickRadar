//
//  QRSubmissionService.m
//  QuickRadar
//
//  Created by Amy Worrall on 26/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRSubmissionService.h"

NSString * const QRRadarSubmissionServiceIdentifier = @"QRRadarSubmissionServiceIdentifier";
NSString * const QROpenRadarSubmissionServiceIdentifier = @"QROpenRadarSubmissionServiceIdentifier";

static NSMutableDictionary *_services;

@implementation QRSubmissionService

@synthesize radar = _radar;

+ (NSDictionary *)services
{
	return [NSDictionary dictionaryWithDictionary:_services];
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
		
		[_services setObject:service forKey:identifier];
		
	}
}


+ (NSSet*)hardDependencies;
{
	return [NSSet set];
}


+ (NSSet*)softDependencies;
{
	return [NSSet set];
}


@end
