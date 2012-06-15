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
}



- (IBAction)submitRadar:(id)sender;
{
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
		}
		
	}];
}

@end
