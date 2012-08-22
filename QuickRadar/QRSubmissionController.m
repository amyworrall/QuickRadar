//
//  RadarSubmission.m
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRSubmissionController.h"
#import "QRSubmissionService.h"

@interface QRSubmissionController ()

@property (nonatomic, strong) NSMutableSet *completed;
@property (nonatomic, strong) NSMutableSet *inProgress;
@property (nonatomic, strong) NSMutableSet *waiting;

@property (nonatomic, copy) void (^progressBlock)() ;
@property (nonatomic, copy) void (^completionBlock)(BOOL, NSError *) ;
@property (assign) BOOL hasFiredCompletionBlock;

@end

@implementation QRSubmissionController


@synthesize radar = _radar;
@synthesize completed = _completed, inProgress = _inProgress, waiting = _waiting;
@synthesize progressBlock = _progressBlock, completionBlock = _completionBlock;
@synthesize hasFiredCompletionBlock = _hasFiredCompletionBlock;


- (void)startWithProgressBlock:(void (^)())progressBlock completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
	if (!self.radar)
	{
		completionBlock(NO, [NSError errorWithDomain:@"No radar object" code:0 userInfo:nil]);
		return;
	}
	
	self.progressBlock = progressBlock;
	self.completionBlock = completionBlock;

	self.completed = [NSMutableSet set];
	self.inProgress = [NSMutableSet set];
	self.waiting = [NSMutableSet set];
	
	
	NSDictionary *services = [QRSubmissionService services];
	
	for (NSString *serviceID in services)
	{
		Class serviceClass = [services objectForKey:serviceID];
		
		if (![serviceClass isAvailable])
		{
			continue;
		}
		
		if ([serviceClass requireCheckBox])
		{
			if ([[self.requestedOptionalServices objectForKey:serviceID] boolValue] == NO)
			{
				continue;
			}
		}
		
		QRSubmissionService *service = [[serviceClass alloc] init];
		service.radar = self.radar;
		
		[self.waiting addObject:service];
	}

	[self startNextAvailableServices];
}

- (void)startNextAvailableServices;
{
	for (QRSubmissionService *service in [self.waiting copy])
	{
		NSSet *hardDeps = [[service class] hardDependencies];
		NSSet *softDeps = [[service class] softDependencies];
		
		BOOL hasFailedDeps = NO;
		
		/* Check hard deps */
		// For a hard dep, if the service in question is NOT completed, it fails.
		for (NSString *serviceID in hardDeps)
		{
			BOOL metThisDep = NO;
			for (QRSubmissionService *testService in [self.completed copy])
			{
				if ([[[testService class] identifier] isEqualToString:serviceID])
				{
					metThisDep = YES;
				}
			}
			if (!metThisDep)
			{
				hasFailedDeps = YES;
			}
		}
		
		// TODO: decide what you're doing about serviceStatus -- either use it here, or remove it everywhere.
		
		/* Check soft deps */
		// For a soft dep, if the service in question is present and not finished, it fails. 
		for (NSString *serviceID in softDeps)
		{
			for (QRSubmissionService *testService in [self.waiting setByAddingObjectsFromSet:self.inProgress])
			{
				if ([[[testService class] identifier] isEqualToString:serviceID])
				{
					hasFailedDeps = YES;
				}
			}
		}
		
		if (hasFailedDeps)
		{
			continue;
		}
		
		/* Get on with it */
		
		[self.inProgress addObject:service];
		[self.waiting removeObject:service];
		
		[service submitAsyncWithProgressBlock:^{
			self.progressBlock();
		} completionBlock:^(BOOL success, NSError *error) {
			[self.inProgress removeObject:service];
			[self.completed addObject:service];
			
			if (!success)
			{
				self.hasFiredCompletionBlock = YES;
				self.completionBlock(NO, error);
			}
			else 
			{
				[self startNextAvailableServices];
			}
			
		}];
	}
	
	if (self.inProgress.count == 0 && self.waiting.count == 0 && !self.hasFiredCompletionBlock)
	{
		self.hasFiredCompletionBlock = YES;
		self.completionBlock(YES, nil);
	}
}

- (CGFloat)progress
{
	CGFloat accumulator = 0;
	CGFloat number = 0;
	
	for (QRSubmissionService *service in self.waiting)
	{
		number++;
		accumulator += service.progress;
	}
	for (QRSubmissionService *service in self.inProgress)
	{
		number++;
		accumulator += service.progress;
	}
	for (QRSubmissionService *service in self.completed)
	{
		number++;
		accumulator += service.progress;
	}
	
	return accumulator/number;
}


@end
