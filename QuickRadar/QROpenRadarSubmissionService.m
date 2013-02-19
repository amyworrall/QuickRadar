//
//  QROpenRadarSubmissionService.m
//  QuickRadar
//
//  Created by Amy Worrall on 21/08/2012.
//
//

#import "QROpenRadarSubmissionService.h"
#import "QRURLConnection.h"


@interface QROpenRadarSubmissionService ()

@property (atomic, assign) CGFloat progressValue;
@property (atomic, assign) SubmissionStatus submissionStatusValue;

@end


@implementation QROpenRadarSubmissionService

+ (void)load
{
	[QRSubmissionService registerService:self];
}

+ (NSString *)identifier
{
	return QROpenRadarSubmissionServiceIdentifier;
}

+ (NSString *)name
{
	return @"Open Radar";
}

+ (NSString*)checkBoxString
{
	return @"Send to Open Radar";
}

+ (BOOL)isAvailable
{
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"openRadarAPIKey"];
	
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
	return @"QROpenRadarSubmissionServicePreferencesViewController";
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

- (void)submitAsyncWithProgressBlock:(void (^)())progressBlock completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		self.submissionStatusValue = submissionStatusInProgress;
		
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
		formatter.dateFormat = @"dd-MMM-yyyy hh:mm a";
		NSString *dateString = [formatter stringFromDate:self.radar.dateOriginated];
		
		NSLog(@"Date originated: %@, formatted %@", self.radar.dateOriginated, dateString);
		
		NSError *error = nil;
		
		NSString *apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"openRadarAPIKey"];
		
		if (apiKey.length == 0 || self.radar.radarNumber == 0)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		
		NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://openradar.appspot.com/api/radars/add"]];
		[req addValue:apiKey forHTTPHeaderField:@"Authorization"];
		req.HTTPMethod = @"POST";
		
		NSDictionary *postParams =
							@{
								@"number" : @(self.radar.radarNumber),
								@"classification" : self.radar.classification,
								@"description" : self.radar.body,
								@"product" : self.radar.product,
								@"product_version" : self.radar.version,
								@"reproducible" : self.radar.reproducible,
								@"title" : self.radar.title,
		@"originated" : dateString,
		@"status" : self.radar.status,
							};
		
		QRURLConnection *conn = [[QRURLConnection alloc] init];
		conn.request = req;
		conn.postParameters = postParams;
		
		NSData *data = [conn fetchSyncWithError:&error];
		
		NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"OR: Result: %@ %@", result, error);
		
		self.progressValue = 1.0;
		self.submissionStatusValue = submissionStatusCompleted;
		self.radar.submittedToOpenRadar = YES;
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			progressBlock();
			completionBlock(YES, nil);
		});
		
	});
}



@end
