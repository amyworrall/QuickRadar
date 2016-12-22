//
//  QRCopyToClipboardSubmissionService.m
//  QuickRadar
//
//  Created by Amy Worrall on 26/09/2012.
//
//

#import "QRCopyToClipboardSubmissionService.h"

@interface QRCopyToClipboardSubmissionService ()

@property (assign) BOOL completed;

@end

@implementation QRCopyToClipboardSubmissionService

+ (void)load
{
	[QRSubmissionService registerService:self];
}

+ (NSString *)identifier
{
	return @"QRCopyToClipboardSubmissionService.h";
}

+ (NSString *)name
{
	return @"Copy to Clipboard";
}

+ (NSString*)checkBoxString
{
	return @"Copy radar number to clipboard";
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
	return nil;
}

+ (NSString*)iosSettingsViewControllerClassName;
{
	return nil;
}

+(NSSet *)hardDependencies
{
	return [NSSet setWithObject:QRRadarSubmissionServiceIdentifier];
}

+(NSSet *)softDependencies
{
	return nil;
}

- (CGFloat)progress
{
	return self.completed ? 1.0 : 0.0;
}

- (SubmissionStatus)submissionStatus
{
	return (self.completed) ? submissionStatusCompleted : submissionStatusNotStarted;
}

- (void)submitAsyncWithProgressBlock:(void (^)())progressBlock completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
	NSString *radarNumString = [NSString stringWithFormat:@"rdar://%li", self.radar.radarNumber];
	
	[[NSPasteboard generalPasteboard] clearContents];
	[[NSPasteboard generalPasteboard] writeObjects:@[radarNumString]];
	
	self.completed = YES;
	
	completionBlock(YES, nil);
}


@end
