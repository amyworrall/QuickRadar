//
//  QRAppDotNetSubmissionServicePreferencesViewController.m
//  QuickRadar
//
//  Created by Amy Worrall on 22/08/2012.
//
//

#import "QRAppDotNetSubmissionServicePreferencesViewController.h"

@interface QRAppDotNetSubmissionServicePreferencesViewController ()

@end

@implementation QRAppDotNetSubmissionServicePreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)authorise:(id)sender
{
	NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AppDotNetConfig" ofType:@"plist"]];
	
	if (!config)
		return;
	
	NSString *clientID = config[@"clientID"];
	NSString *requestURI = [config[@"redirectURI"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	NSString *stringURL = [NSString stringWithFormat:@"https://alpha.app.net/oauth/authenticate?client_id=%@&response_type=token&redirect_uri=%@&scope=write_post", clientID, requestURI];
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:stringURL]];
}

- (IBAction)forgetAuth:(id)sender;
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"appDotNetUserToken"];
}

@end
