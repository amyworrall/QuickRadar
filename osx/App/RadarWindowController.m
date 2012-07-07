//
//  RadarWindowController.m
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RadarWindowController.h"
#import "RadarSubmission.h"

#import <Growl/Growl.h>

@implementation RadarWindowController

@synthesize spinner, openRadarCheckbox, titleField, bodyTextView, classificationMenu, versionField, productMenu, reproducibleMenu, submitButton;


- (void)windowDidLoad
{
	NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
	
	[self.productMenu removeAllItems];
	[self.classificationMenu removeAllItems];
	[self.reproducibleMenu removeAllItems];
	
	for (NSString *str in [config objectForKey:@"products"])
	{
		[self.productMenu addItemWithTitle:str];
	}
	for (NSString *str in [config objectForKey:@"classifications"])
	{
		[self.classificationMenu addItemWithTitle:str];
	}
	for (NSString *str in [config objectForKey:@"reproducible"])
	{
		[self.reproducibleMenu addItemWithTitle:str];
	}
	
	[self.titleField becomeFirstResponder];
    
//	/*dummy msg for testing*/
//    [self.productMenu selectItemWithTitle:@"Bug Reporter"];
//    [self.classificationMenu selectItemWithTitle:@"Feature (New)"];
//    [self.reproducibleMenu selectItemWithTitle:@"Not Applicable"];
//    self.versionField.stringValue = @"latest";
//    self.titleField.stringValue = @"It would be awesome if you added the ability to edit ones bugs.";
//    self.bodyTextView.string = @"So that I can remove my typos :D (I mean the problem description).";
}



- (IBAction)submitRadar:(id)sender;
{
    //hack to show login details
    NSUserDefaults *    prefs = [NSUserDefaults standardUserDefaults];
    NSString *username = [prefs objectForKey: @"username"];
    if (!username) {
        [[[NSApp delegate] window] makeKeyAndOrderFront:nil];
        return;
    }
        
	RadarSubmission *s = [[RadarSubmission alloc] init];
	s.product = self.productMenu.selectedItem.title;
	s.classification = self.classificationMenu.selectedItem.title;
	s.reproducible = self.reproducibleMenu.selectedItem.title;
	s.version = self.versionField.stringValue;
	s.title = self.titleField.stringValue;
	s.body = self.bodyTextView.string;
	
	[self.submitButton setEnabled:NO];
	[self.spinner startAnimation:self];
	
	[s submitWithCompletionBlock:^(BOOL success) 
	{
		if (success && s.radarNumber.intValue > 0)
		{
			[GrowlApplicationBridge notifyWithTitle:@"Submission Complete" 
										description:[NSString stringWithFormat:@"Bug submitted as number %@.", s.radarNumber] 
								   notificationName:@"Submission Complete" 
										   iconData:nil
										   priority:0 
										   isSticky:NO 
									   clickContext:[NSDictionary dictionaryWithObject:s.radarURL forKey:@"URL"]];

			[self.window close];
		}
		else 
		{
			[GrowlApplicationBridge notifyWithTitle:@"Submission Failed" 
										description:@"Submission failed" 
								   notificationName:@"Submission Failed" 
										   iconData:nil 
										   priority:0 
										   isSticky:YES 
									   clickContext:nil];
			[self.submitButton setEnabled:YES];
			[self.spinner stopAnimation:self];

		}
		
	}];
}

@end
