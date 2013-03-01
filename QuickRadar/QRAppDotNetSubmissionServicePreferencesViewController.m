//
//  QRAppDotNetSubmissionServicePreferencesViewController.m
//  QuickRadar
//
//  Created by Amy Worrall on 22/08/2012.
//
//

#import "QRAppDotNetSubmissionServicePreferencesViewController.h"

#define appDotNetUserTokenKey @"appDotNetUserToken"

@interface QRAppDotNetSubmissionServicePreferencesViewController ()

@end

@implementation QRAppDotNetSubmissionServicePreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatusString) name:@"AppDotNetAuthChangedNotification" object:nil];
    }
    
    return self;
}

- (void)loadView
{
	[super loadView];
	[self updateStatusString];
}

- (void)authorise:(id)sender
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	NSString *token = [prefs objectForKey:appDotNetUserTokenKey];
	
	if (token.length==0)
	{
		// need to authorise
		NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AppDotNetConfig" ofType:@"plist" inDirectory:@"Config"]];
		
		if (!config)
		{
			NSRunAlertPanel(@"Config not available", @"App.net config file not found. If you compiled QuickRadar from source, see the file QuickRadar/Config/Readme.md for how to create this file.", @"OK", nil, nil);
			NSLog(@"App.net config file not found. If you compiled QuickRadar from source, see the file QuickRadar/Config/Readme.md for how to create this file.");
			return;
		}
		
		NSString *clientID = config[@"clientID"];
		NSString *requestURI = [config[@"redirectURI"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		NSString *stringURL = [NSString stringWithFormat:@"https://alpha.app.net/oauth/authenticate?client_id=%@&response_type=token&redirect_uri=%@&scope=write_post", clientID, requestURI];
		
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:stringURL]];
	}
	else
	{
		// need to deauthorise
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"appDotNetUserToken"];
	}
	
	[self updateStatusString];
}

- (void)updateStatusString
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSString *token = [prefs objectForKey:appDotNetUserTokenKey];
	
	if (token.length==0)
	{
		[self.statusLabel setStringValue:@"Not Connected"];
		[self.authButton setTitle:@"Authorise with App.net"];
	}
	else
	{
		[self.statusLabel setStringValue:@"Connected"];
		[self.authButton setTitle:@"Disconnect"];
	}

}

- (IBAction)obtainAccount:(id)sender
{
	NSString *stringURL = @"http://join.app.net";
	NSURL *url = [NSURL URLWithString:stringURL];
	[[NSWorkspace sharedWorkspace] openURL:url];

}

@end
