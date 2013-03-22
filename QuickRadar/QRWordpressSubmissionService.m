//
//  QRWordpressSubmissionService.m
//  QuickRadar
//
//  Created by Oliver Drobnik on 22.03.13.
//
//

#import "QRWordpressSubmissionService.h"
#import "NSError+Additions.h"
#import "DTWordpress.h"

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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *endpointURLString = [defaults stringForKey:@"WordpressURL"];
    NSURL *endpointURL = [NSURL URLWithString:endpointURLString];
    NSString *userName = [defaults stringForKey:@"WordpressUser"];
    NSString *password = [defaults stringForKey:@"WordpressPassword"];
    
    NSString *scheme = [endpointURL scheme];
    
    if (!endpointURL || !([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]))
    {
        return NO;
    }
    
    if (![userName length])
    {
        return NO;
    }

    if (![password length])
    {
        return NO;
    }

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
	return [NSSet setWithObject:QRRadarSubmissionServiceIdentifier];
}

+(NSSet *)softDependencies
{
	return [NSSet setWithObject:QROpenRadarSubmissionServiceIdentifier];
}

- (void)submitAsyncWithProgressBlock:(void (^)())progressBlock completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
    // TODO: implement wordpress submission here
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *endpointURLString = [defaults stringForKey:@"WordpressURL"];
    NSURL *endpointURL = [NSURL URLWithString:endpointURLString];
    NSString *userName = [defaults stringForKey:@"WordpressUser"];
    NSString *password = [defaults stringForKey:@"WordpressPassword"];

        NSString *scheme = [endpointURL scheme];
    
    if (!endpointURL || !([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]))
    {
        return;
    }
    
    if (![userName length])
    {
        return;
    }
    
    if (![password length])
    {
        return;
    }
    
    DTWordpress *wordpress = [[DTWordpress alloc] initWithEndpointURL:endpointURL];
    wordpress.userName = userName;
    wordpress.password = password;
    
    NSString *title = [NSString stringWithFormat:@"Radar: %@", self.radar.title];
    NSMutableString *description = [NSMutableString string];
    
    [description appendFormat:@"Submitted as rdar://%ld", self.radar.radarNumber];
    
	if (self.radar.submittedToOpenRadar)
	{
        [description appendFormat:@" and to <a href=\"http://openradar.me/%ld\">OpenRadar</a>", self.radar.radarNumber];
	}
    
    [description appendString:@".\n\n"];
    
    [description appendString:self.radar.body];
    
    NSDictionary *content = @{@"title":title, @"description":description, @"post_type":@"post"};
    
    [wordpress newPostWithContent:content shouldPublish:NO completion:^(NSInteger postID, NSError *error) {
        if (error)
        {
            // wrap authentication error
            if (error.code == 403)
            {
                error = [NSError authenticationErrorWithServiceIdentifier:QRWordpressSubmissionServiceIdentifier underlyingError:error];
            }
            
            progressBlock();
            completionBlock(NO, error);
        }
        else
        {
            NSLog(@"new post id %ld", (long)postID);
            
            progressBlock();
            completionBlock(YES, nil);
        }
    }];
}


@end
