//
//  QRTwitterSubmissionService.m
//  QuickRadar
//
//  Created by Amy Worrall on 19/02/2013.
//
//

#import "QRTwitterSubmissionService.h"

@interface QRTwitterSubmissionService ()<NSSharingServiceDelegate>

@property (nonatomic, assign) BOOL hasTweeted;
@property (nonatomic, copy) void(^completionBlock)(BOOL, NSError *);

@end


@implementation QRTwitterSubmissionService

+ (void)load
{
	[QRSubmissionService registerService:self];
}

+ (NSString *)identifier
{
	return QRTwitterSubmissionServiceIdentifier;
}

+ (NSString *)name
{
	return @"Twitter";
}

+ (NSString*)checkBoxString
{
	return @"Post to Twitter";
}

+ (BOOL)isAvailable
{
	if (!NSClassFromString(@"NSSharingService"))
	{
		return NO;
	}
	
	return [[NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter] canPerformWithItems:nil];
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
	return nil;
}

+ (NSString*)iosSettingsViewControllerClassName;
{
	return nil;
}

+ (id)settingsIconPlatformAppropriateImage;
{
	return nil;
}

- (CGFloat)progress
{
	if (self.hasTweeted) {
		return 1.0;
	}
	return 0.0;
}

- (SubmissionStatus)submissionStatus
{
	if (self.hasTweeted) {
		return submissionStatusNotStarted;
	}
	return submissionStatusCompleted;
}

+(NSSet *)hardDependencies
{
	return [NSSet setWithObject:QRRadarSubmissionServiceIdentifier];
}

+(NSSet *)softDependencies
{
	return [NSSet setWithObject:QROpenRadarSubmissionServiceIdentifier];
}

- (void)submitAsyncWithProgressBlock:(void (^)())progressBlock completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
	self.completionBlock = completionBlock;
	
	NSSharingService *s = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
	s.delegate = self;
	
	NSString *radarLink;
	if (self.radar.submittedToOpenRadar)
	{
		radarLink = [NSString stringWithFormat:@"http://openradar.me/%ld", self.radar.radarNumber];
	}
	else
	{
		radarLink = [NSString stringWithFormat:@"rdar://%ld", self.radar.radarNumber];
	}
	
	NSString *post = [NSString stringWithFormat:@"Radar: %@", self.radar.title];
	NSURL *link = [NSURL URLWithString:radarLink];

	
	dispatch_async(dispatch_get_main_queue(), ^{
		[s performWithItems:@[post, link]];
	});
	
}


- (void)sharingService:(NSSharingService *)sharingService didFailToShareItems:(NSArray *)items error:(NSError *)error;
{
	self.completionBlock(NO, error);
}

- (void)sharingService:(NSSharingService *)sharingService didShareItems:(NSArray *)items;
{
	self.completionBlock(YES, nil);
}

- (NSWindow *)sharingService:(NSSharingService *)sharingService sourceWindowForShareItems:(NSArray *)items sharingContentScope:(NSSharingContentScope *)sharingContentScope;
{
	return self.submissionWindow;
}

@end
