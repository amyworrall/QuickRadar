//
//  RadarWindowController.m
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRRadarWindowController.h"
#import "QRSubmissionController.h"
#import "QRSubmissionService.h"
#import "QRRadar.h"
#import <Growl/Growl.h>
#import "QRAppListPopover.h"
#import "QRCachedRunningApplication.h"
#import "NSButton+QuickRadar.h"
#import "AppDelegate.h"

@interface QRRadarWindowController ()

@property (nonatomic, strong) QRSubmissionController *submissionController;
@property (nonatomic) BOOL userTypedTitle;	// Don't override his title when selecting an app.
@property (nonatomic, strong) QRRadar *radarToPrepopulate;

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
	
	[self setUpCheckboxes];
	
	if (self.radarToPrepopulate.body.length>0)
	{
		self.bodyTextView.string = self.radarToPrepopulate.body;
	}
	else
	{
		self.bodyTextView.string =
        @"Summary:\n"
        @"Provide a descriptive summary of the issue.\n"
        @"\n"
        @"Steps to Reproduce:\n"
        @"In numbered format, detail the exact steps taken to produce the bug.\n"
        @"\n"
        @"Expected Results:\n"
        @"Describe what you expected to happen when you executed the steps above.\n"
        @"\n"
        @"Actual Results:\n"
        @"Explain what actually occurred when steps above were executed.\n"
        @"\n"
        @"Regression:\n"
        @"Describe circumstances where the problem occurs or does not occur, such as software versions and/or hardware configurations.\n"
        @"\n"
        @"Notes:\n"
        @"Provide additional information, such as references to related problems, workarounds and relevant attachments.\n\n\n";
	}
	
	if (self.radarToPrepopulate.title.length>0)
	{
		self.titleField.stringValue = self.radarToPrepopulate.title;
	}
	
	if (self.radarToPrepopulate.version.length>0)
	{
		self.versionField.stringValue = self.radarToPrepopulate.version;
	}
	
	[self menuButton:self.classificationMenu selectItemTitle:self.radarToPrepopulate.classification];
	[self menuButton:self.productMenu selectItemTitle:self.radarToPrepopulate.product];
	[self menuButton:self.reproducibleMenu selectItemTitle:self.radarToPrepopulate.reproducible];
	
	self.userTypedTitle = NO;
	[self.titleField becomeFirstResponder];
	
}

- (void)prepopulateWithRadar:(QRRadar *)radar;
{
	self.radarToPrepopulate = radar;
}

- (void)menuButton:(NSPopUpButton*)button selectItemTitle:(NSString*)itemTitle
{
	if (itemTitle.length==0)
	{
		return;
	}
	
	NSMenuItem *item = [button itemWithTitle:itemTitle];
	if (item)
	{
		[self.reproducibleMenu selectItem:item];
		return;
	}
	
	NSString *trimmedNeedle = [itemTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	for (NSString *aTitle in button.itemTitles)
	{
		NSString *trimmedHaystack = [aTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if ([trimmedNeedle compare:trimmedHaystack options:NSCaseInsensitiveSearch]==NSOrderedSame)
		{
			item = [button itemWithTitle:aTitle];
			[self.reproducibleMenu selectItem:item];
			return;
		}
	}
}

- (void)setUpCheckboxes
{
	NSDictionary *checkboxDict = [QRSubmissionService checkBoxNames];
	[self.checkboxMatrix renewRows:checkboxDict.count columns:1];
	NSArray *orderedServiceIDs = [checkboxDict.allKeys sortedArrayUsingSelector:@selector(compare:)];
	
	for (int i=0; i<orderedServiceIDs.count; i++)
	{
		NSString *serviceID = [orderedServiceIDs objectAtIndex:i];
		NSString *checkboxText = [checkboxDict objectForKey:serviceID];
		
		NSCell *cell = [self.checkboxMatrix cellAtRow:i column:0];
		cell.title = checkboxText;
		cell.representedObject = serviceID;
	}
}

- (IBAction)showAppList:(id)sender {
	[self.appListPopover showRelativeToRect:self.appListButton.frame ofView:self.appListButton.superview preferredEdge:NSMaxXEdge];
}

- (void)prepopulateWithApp:(QRCachedRunningApplication *)app {
	// Fill out the versions text field using the selected app.
	NSString *text = app.unlocalizedName;
	NSString *versionAndBuild = app.versionAndBuild;
	if (versionAndBuild) text = [text stringByAppendingFormat:@" %@", versionAndBuild];
	versionField.stringValue = text;
	
	// Apple also recommends to include the version in the title.
	// https://developer.apple.com/bugreporter/bugbestpractices.html#BugBody
	// We have to make sure, we don't override the title, if the user already typed in something.
	// But we want to override it, if it's just an other app's version. self.userTypedTitle will be YES, if the user already typed something.
	NSString *trimmedTitle = [titleField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t"]];
	if (!trimmedTitle || [trimmedTitle isEqualToString:@""] || self.userTypedTitle == NO) {
		NSString *title = app.unlocalizedName;
		NSString *version = app.version;
		NSString *build = app.build;
		if (version) title = [title stringByAppendingFormat:@" %@: ", version];
		else if (build) title = [title stringByAppendingFormat:@" (%@): ", build];
		titleField.stringValue = title;
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
        [((AppDelegate*)[NSApp delegate]) showPreferencesWindow:self];
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
	radar.dateOriginated = [NSDate date];
	radar.status = @"Open";

	
	/* Submit it */
	
	[self.submitButton setEnabled:NO];
	[self.spinner startAnimation:self];
	
	self.submissionController = [[QRSubmissionController alloc] init];
	self.submissionController.radar = radar;
	
	// Get checkbox statuses
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	for (int i=0; i<self.checkboxMatrix.numberOfRows; i++)
	{
		NSCell *cell = [self.checkboxMatrix cellAtRow:i column:0];
		BOOL selected = [cell integerValue];
		
		[dict setObject:@(selected) forKey:cell.representedObject];
	}
	self.submissionController.requestedOptionalServices = [NSDictionary dictionaryWithDictionary:dict];
	
	[self.submissionController startWithProgressBlock:^{
		self.progressBar.doubleValue = self.submissionController.progress;
	} completionBlock:^(BOOL success, NSError *error) {
		if (success && radar.radarNumber > 0)
		{
			NSDictionary *clickContext = nil;
			if (radar.submittedToOpenRadar)
			{
				clickContext = @{ @"URL" : [NSString stringWithFormat:@"http://openradar.me/%ld", radar.radarNumber] };
			}
			
			[GrowlApplicationBridge notifyWithTitle:@"Submission Complete"
										description:[NSString stringWithFormat:@"Bug submitted as number %ld.", radar.radarNumber]
								   notificationName:@"Submission Complete"
										   iconData:nil
										   priority:0
										   isSticky:NO
									   clickContext:clickContext];
			
			
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

- (void)controlTextDidChange:(NSNotification *)aNotification {
	self.userTypedTitle = YES;
}

@end
