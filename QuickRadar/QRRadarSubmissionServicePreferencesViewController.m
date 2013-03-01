//
//  QRRadarSubmissionServicePreferencesViewController.m
//  QuickRadar
//
//  Created by Amy Worrall on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRRadarSubmissionServicePreferencesViewController.h"

@interface QRRadarSubmissionServicePreferencesViewController ()

@end

@implementation QRRadarSubmissionServicePreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)getAnAccount:(id)sender
{
	NSString *stringURL = @"https://developer.apple.com/programs/register/";
	NSURL *url = [NSURL URLWithString:stringURL];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

@end
