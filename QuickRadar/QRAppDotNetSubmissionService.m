//
//  QRAppDotNetSubmissionService.m
//  QuickRadar
//
//  Created by Amy Worrall on 22/08/2012.
//
//

#import "QRAppDotNetSubmissionService.h"
#import "QRURLConnection.h"
#import "QRUserDefaultsKeys.h"

@interface QRAppDotNetSubmissionService ()

@property (atomic, assign) CGFloat progressValue;
@property (atomic, assign) SubmissionStatus submissionStatusValue;

@end

@implementation QRAppDotNetSubmissionService



+ (void)load
{
	[QRSubmissionService registerService:self];
}

+ (NSString *)identifier
{
	return @"QRAppDotNetSubmissionServiceIdentifier";
}

+ (NSString *)name
{
	return @"AppDotNet";
}

+ (NSString*)checkBoxString
{
	return @"Send to App.net";
}

+ (BOOL)isAvailable
{
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"appDotNetUserToken"];
	
	if (apiKey.length > 0)
	{
		return YES;
	}
	return NO;
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
	return @"QRAppDotNetSubmissionServicePreferencesViewController";
}

+ (NSString*)iosSettingsViewControllerClassName;
{
	return nil;
}

+ (id)settingsIconPlatformAppropriateImage;
{
	if (NSClassFromString(@"NSImage"))
	{
		return [NSImage imageNamed:@"ADNLogoTemplate"];
	}
	return nil;
}

- (CGFloat)progress
{
	return self.progressValue;
}

- (SubmissionStatus)submissionStatus
{
	return self.submissionStatusValue;
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
	BOOL postRdarURLs = [[NSUserDefaults standardUserDefaults] boolForKey:QRAppDotNetIncludeRdarLinksKey];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		self.submissionStatusValue = submissionStatusInProgress;
		
		NSError *error = nil;
		
		NSString *apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"appDotNetUserToken"];
		
		if (apiKey.length == 0 || self.radar.radarNumber == 0)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		
		
		NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://alpha-api.app.net/stream/0/posts"]];
		[req addValue:[NSString stringWithFormat:@"Bearer %@", apiKey] forHTTPHeaderField:@"Authorization"];
		req.HTTPMethod = @"POST";
		
		NSString *radarLink;
		if (self.radar.submittedToOpenRadar)
		{
			radarLink = [NSString stringWithFormat:@"http://openradar.me/%ld", self.radar.radarNumber];
		}
		else
		{
			radarLink = [NSString stringWithFormat:@"rdar://problem/%ld", self.radar.radarNumber];
		}
		
		NSString *afterwards = @"";
		if (self.radar.submittedToOpenRadar && postRdarURLs)
		{
			afterwards = [NSString stringWithFormat:@" (rdar://problem/%ld)", self.radar.radarNumber];
		}
		
		NSString *post = [NSString stringWithFormat:@"%@%@", self.radar.title, afterwards];
		
		
		NSDictionary *entitiesDict = @{
								 @"links" : @[
				 @{
		 @"pos": @0,
	   @"len": @(self.radar.title.length),
	   @"url": radarLink
   }
				 ],
		 @"parse_links" : @(YES)
		 };
		
		NSDictionary *postParams =
		@{ @"text" : post,
	 @"entities" : entitiesDict
	 };
		NSLog(@"Sending %@", postParams);
		
		QRURLConnection *conn = [[QRURLConnection alloc] init];
		conn.request = req;
		conn.postParameters = postParams;
		conn.sendPostParamsAsJSON = YES;
		
		NSData *data = [conn fetchSyncWithError:&error];
		
		NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"Result: %@ %@", result, error);
		
		self.progressValue = 1.0;
		self.submissionStatusValue = submissionStatusCompleted;
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			progressBlock();
			completionBlock(YES, nil);
		});

		
	});
}

@end
