//
//  RadarWindowController.m
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRRadarWindowController.h"
#import "QRSubmissionController.h"
#import "QRRadar.h"
#import <Growl/Growl.h>
#import "QRAppListPopover.h"
#import "QRCachedRunningApplication.h"
#import "NSButton+QuickRadar.h"

@interface QRRadarWindowController ()

@property (nonatomic, strong) QRSubmissionController *submissionController;

@end


@implementation QRRadarWindowController

@synthesize spinner, openRadarCheckbox, titleField, bodyTextView, classificationMenu, versionField, productMenu, reproducibleMenu, submitButton;
@synthesize submissionController = _submissionController;
@synthesize progressBar = _progressBar;
@synthesize appListButton;
@synthesize appListPopover;

- (void)windowDidLoad
{
	NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
	
	[self.productMenu removeAllItems];
	[self.classificationMenu removeAllItems];
	[self.reproducibleMenu removeAllItems];
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	for (NSString *str in [config objectForKey:@"products"])
	{
		[self.productMenu addItemWithTitle:str];
		if ([str isEqualToString:[prefs objectForKey:@"RadarWindowSelectedProduct"]])
		{
			[self.productMenu selectItemWithTitle:str];
		}
	}
	for (NSString *str in [config objectForKey:@"classifications"])
	{
		[self.classificationMenu addItemWithTitle:str];
		if ([str isEqualToString:[prefs objectForKey:@"RadarWindowSelectedClassification"]])
		{
			[self.classificationMenu selectItemWithTitle:str];
		}
	}
	for (NSString *str in [config objectForKey:@"reproducible"])
	{
		[self.reproducibleMenu addItemWithTitle:str];
		if ([str isEqualToString:[prefs objectForKey:@"RadarWindowSelectedReproducible"]])
		{
			[self.reproducibleMenu selectItemWithTitle:str];
		}
	}
	
	
	[self.titleField becomeFirstResponder];
	
}

- (IBAction)showAppList:(id)sender {
	[self.appListPopover showRelativeToRect:self.appListButton.frame ofView:self.appListButton.superview preferredEdge:NSMaxXEdge];
}

- (void)prepopulateWithApp:(QRCachedRunningApplication *)app {
	// Fill out the versions text field using the selected app.
	NSString *text = app.unlocalizedName;
	NSString *version = app.versionAndBuild;
	if (version) text = [text stringByAppendingFormat:@" %@", version];
	versionField.stringValue = text;
	
	// Apple alre recommends to include the version in the title.
	// https://developer.apple.com/bugreporter/bugbestpractices.html#BugBody
	NSString *trimmedTitle = [titleField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t"]];
	if (!trimmedTitle || [trimmedTitle isEqualToString:@""]) {
		titleField.stringValue = [text stringByAppendingString:@": "];
	}
	
	// Try to guess the category for the selected app (Xcode -> Developer Tools, Pages -> iWork, etc.)
	NSString *guess = [app guessCategory];
	NSMenuItem *item = [self.productMenu itemWithTitle:guess];
	if (item) {
		[self.productMenu selectItem:item];
		[self.productMenu blinkTwice];
	}
	
	// If the selected app crashed recently, choose Crash from the Classification list.
	if ([app didCrashRecently]) {
		for (NSString *title in self.classificationMenu.itemTitles) {
			if ([title rangeOfString:@"Crash"].location != NSNotFound) {
				[self.classificationMenu selectItemWithTitle:title];
				[self.classificationMenu blinkTwice];
			}
		}
	}
	
	[self.titleField becomeFirstResponder];
}

- (void)appListPopover:(QRAppListPopover *)popover selectedApp:(QRCachedRunningApplication *)app {
	[self prepopulateWithApp:app];
	[self.appListPopover close];
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
	
	/* Save UI state */
	
	[prefs setObject:self.productMenu.selectedItem.title forKey:@"RadarWindowSelectedProduct"];
	[prefs setObject:self.classificationMenu.selectedItem.title forKey:@"RadarWindowSelectedClassification"];
	[prefs setObject:self.reproducibleMenu.selectedItem.title forKey:@"RadarWindowSelectedReproducible"];
	
	/* Make a radar */
	
	QRRadar *radar = [[QRRadar alloc] init];
	radar.product = self.productMenu.selectedItem.title;
	radar.classification = self.classificationMenu.selectedItem.title;
	radar.reproducible = self.reproducibleMenu.selectedItem.title;
	radar.version = self.versionField.stringValue;
	radar.title = self.titleField.stringValue;
	radar.body = self.bodyTextView.string;
	
	/* Submit it */
	
	[self.submitButton setEnabled:NO];
	[self.spinner startAnimation:self];
	
	self.submissionController = [[QRSubmissionController alloc] init];
	self.submissionController.radar = radar;
	
	return;
	[self.submissionController startWithProgressBlock:^{
		self.progressBar.doubleValue = self.submissionController.progress;
	} completionBlock:^(BOOL success, NSError *error) {
		if (success && radar.radarNumber > 0)
		{
			[GrowlApplicationBridge notifyWithTitle:@"Submission Complete"
										description:[NSString stringWithFormat:@"Bug submitted as number %i.", radar.radarNumber]
								   notificationName:@"Submission Complete"
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:nil];
			
			// Move the window off screen, like Mail.app
			CGFloat highestScreenHeight = 0.0f;
			for (NSScreen *screen in [NSScreen screens]) {
				highestScreenHeight = MAX(highestScreenHeight, screen.frame.size.height);
			}
			CGRect rect = CGRectMake(self.window.frame.origin.x, highestScreenHeight + 200,
									 self.window.frame.size.width, self.window.frame.size.height);
			[self.window setFrame:rect display:YES animate:YES];
			
			// Close when animation is done.
			[self.window performSelector:@selector(close) withObject:nil afterDelay:[self.window animationResizeTime:rect]];
//			[self.window close];
		}
		else
		{
			[NSApp presentError:error];
			
			
			[self.submitButton setEnabled:YES];
			[self.spinner stopAnimation:self];
			
		}
		
	}];
	
	
}

@end
