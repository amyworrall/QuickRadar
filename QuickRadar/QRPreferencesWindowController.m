//
//  PreferencesWindowController.m
//  QuickRadar
//
//  Created by Amy Worrall on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRPreferencesWindowController.h"
#import "QRMainAppSettingsViewController.h"
#import "QRSubmissionService.h"

@interface QRPreferencesWindowController ()

@end

@implementation QRPreferencesWindowController
@synthesize contentBox = _contentBox;
@synthesize panes = _panes;
@synthesize panesArrayController = _panesArrayController;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) 
	{
        
		NSMutableArray *prefPanes = [NSMutableArray array];
		
		QRMainAppSettingsViewController *mainPrefsVC = [[QRMainAppSettingsViewController alloc] init];
		mainPrefsVC.title = @"App Settings";
		mainPrefsVC.representedObject = [NSImage imageNamed:NSImageNameActionTemplate];
		[prefPanes addObject:mainPrefsVC];
		
		NSDictionary *services = [QRSubmissionService services];

		for (NSString *serviceID in services)
		{
			Class serviceClass = [services objectForKey:serviceID];
			
			NSString *viewControllerClassName = [serviceClass macSettingsViewControllerClassName];
			if (viewControllerClassName.length>0)
			{
				Class viewControllerClass = NSClassFromString(viewControllerClassName);
				NSViewController *viewController = [[viewControllerClass alloc] initWithNibName:viewControllerClassName bundle:nil];
				
				viewController.title = [serviceClass name];
				viewController.representedObject = [serviceClass settingsIconPlatformAppropriateImage];
				
				[prefPanes addObject:viewController];
			}
		}
		
		
		self.panes = [NSArray arrayWithArray:prefPanes];
		
    }
    
    return self;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == self.panesArrayController)
	{
		[self updateActiveView];
	}
}

- (void)updateActiveView
{
	if (self.panesArrayController.selectedObjects.count == 0)
	{
		return;
	}
	
	NSViewController *vc = [[self.panesArrayController selectedObjects] objectAtIndex:0];
	
	[self.contentBox setContentView:vc.view];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	[self.panesArrayController addObserver:self
								forKeyPath:@"selectedObjects"
								   options:0
								   context:NULL];

	[self updateActiveView];
}

- (void)dealloc
{
	[self.panesArrayController removeObserver:self forKeyPath:@"selectedObjects"];
}

@end
