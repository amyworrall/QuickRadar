//
//  QRWordpressSubmissionService.m
//  QuickRadar
//
//  Created by Oliver Drobnik on 22.03.13.
//
//

#import "QRWordpressSubmissionService.h"

@implementation QRWordpressSubmissionService

+ (void)load
{
	[QRSubmissionService registerService:self];
}

+ (NSString *)identifier
{
	return QRWordpressSubmissionServiceIdentifier;
}

+ (NSString *)name
{
	return @"Wordpress";
}

+ (NSString*)checkBoxString
{
	return @"Send to Wordpress Blog";
}

+ (BOOL)isAvailable
{
    return YES;
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
	return @"QRWordpressSubmissionServicePreferencesViewController";
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
	return 0;
}

- (SubmissionStatus)submissionStatus
{
	return submissionStatusCompleted;
}

+(NSSet *)hardDependencies
{
    return nil;
	return [NSSet setWithObject:QRRadarSubmissionServiceIdentifier];
}

+(NSSet *)softDependencies
{
    return nil;
	return [NSSet setWithObject:QROpenRadarSubmissionServiceIdentifier];
}

- (void)submitAsyncWithProgressBlock:(void (^)())progressBlock completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
    // TODO: implement wordpress submission here
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        progressBlock();
        completionBlock(YES, nil);
    });
}


@end
