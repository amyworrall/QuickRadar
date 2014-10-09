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

- (QRAppListViewController *) listViewController
{
	return (QRAppListViewController *)self.contentViewController;
}

// When building with SDKs older than 10.10, we have to call viewWillAppear et. al. manually,
// but on 10.10 and greater the view system will call it for us. Avoid calling it twice...
#if MAC_OS_X_VERSION_10_9 <= MAC_OS_X_VERSION_MAX_ALLOWED
- (void)popoverWillShow:(NSNotification *)notification {
	[[self listViewController] viewWillAppear];
}

- (void)popoverDidShow:(NSNotification *)notification {
	[[self listViewController] viewDidAppear];
}

- (void)popoverWillClose:(NSNotification *)notification {
	[[self listViewController] viewWillDisappear];
}

- (void)popoverDidClose:(NSNotification *)notification {
	[[self listViewController] viewDidDisappear];
}
#endif

- (void)selectedApp:(QRCachedRunningApplication *)app {
	if ([self.appListDelegate respondsToSelector:@selector(appListPopover:selectedApp:)]) {
		[self.appListDelegate appListPopover:self selectedApp:app];
	}
}

@end
