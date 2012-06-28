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


@end

@implementation QRSubmissionController


@synthesize radar = _radar;
@synthesize completed = _completed, inProgress = _inProgress, waiting = _waiting;
@synthesize progressBlock = _progressBlock, completionBlock = _completionBlock;


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
	
	NSLog(@"Services: %@", services);
	
	for (NSString *serviceID in services)
	{
		Class serviceClass = [services objectForKey:serviceID];
		
		QRSubmissionService *service = [[serviceClass alloc] init];
		service.radar = self.radar;
		
		[self.waiting addObject:service];
	}
	
	[self startNextAvailableServices];
}

- (void)startNextAvailableServices;
{
	for (QRSubmissionService *service in self.waiting)
	{
		[self.inProgress addObject:service];
		[self.waiting removeObject:service];
		
		[service submitAsyncWithProgressBlock:^{
			NSLog(@"Progress %f", service.progress);
			self.progressBlock();
		} completionBlock:^(BOOL success, NSError *error) {
			[self.inProgress removeObject:service];
			[self.completed removeObject:service];
			[self startNextAvailableServices];
		}];
	}
	
	if (self.inProgress.count == 0 && self.completed.count == 0)
	{
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
