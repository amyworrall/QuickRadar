//
//  QROpenRadarSubmissionServicePreferencesViewController.m
//  QuickRadar
//
//  Created by Amy Worrall on 21/08/2012.
//
//

#import "QROpenRadarSubmissionServicePreferencesViewController.h"

@interface QROpenRadarSubmissionServicePreferencesViewController ()

@end

@implementation QROpenRadarSubmissionServicePreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)jumpToAPIKeyPage:(id)sender
{
	NSLog(@"Opening");
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://openradar.appspot.com/apikey"]];
}

@end
