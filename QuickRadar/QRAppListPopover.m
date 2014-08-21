//
//  QRAppListPopover.m
//  RunningApps
//
//  Created by Balázs Faludi on 16.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//

#import "QRAppListPopover.h"
#import "QRAppListViewController.h"
#import "QRCachedRunningApplication.h"



@implementation QRAppListPopover

// On versions of Mac OS X earlier than 10.10, we have to call viewWillAppear et. al. manually,
// but on 10.10 and greater the view system will call it for us. Avoid calling it twice...
- (BOOL) isMavericksOrOlder
{
	// 1265 is the same as NSAppKitVersionNumber10_9. The latter constant doesn't exist on Mavericks!
	return (floor(NSAppKitVersionNumber) <= 1265);	
}

- (QRAppListViewController *) listViewController
{
	return (QRAppListViewController *)self.contentViewController;
}

- (void)popoverWillShow:(NSNotification *)notification {
	if ([self isMavericksOrOlder]) {
		[[self listViewController] viewWillAppear];
	}
}

- (void)popoverDidShow:(NSNotification *)notification {
	if ([self isMavericksOrOlder]) {
		[[self listViewController] viewDidAppear];
	}
}

- (void)popoverWillClose:(NSNotification *)notification {
	if ([self isMavericksOrOlder]) {
		[[self listViewController] viewWillDisappear];
	}
}

- (void)popoverDidClose:(NSNotification *)notification {
	if ([self isMavericksOrOlder]) {
		[[self listViewController] viewDidDisappear];
	}
}

- (void)selectedApp:(QRCachedRunningApplication *)app {
	if ([self.appListDelegate respondsToSelector:@selector(appListPopover:selectedApp:)]) {
		[self.appListDelegate appListPopover:self selectedApp:app];
	}
}

@end
