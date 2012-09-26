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

- (void)showRelativeToRect:(NSRect)positioningRect ofView:(NSView *)positioningView preferredEdge:(NSRectEdge)preferredEdge {
//	QRAppListViewController *viewController = (QRAppListViewController *)self.contentViewController;
//	[viewController updateHeight];
	[super showRelativeToRect:positioningRect ofView:positioningView preferredEdge:preferredEdge];
}

- (void)popoverWillShow:(NSNotification *)notification {
	QRAppListViewController *viewController = (QRAppListViewController *)self.contentViewController;
	[viewController viewWillAppear];
}

- (void)popoverDidShow:(NSNotification *)notification {
	QRAppListViewController *viewController = (QRAppListViewController *)self.contentViewController;
	[viewController viewDidAppear];
}

- (void)popoverWillClose:(NSNotification *)notification {
	QRAppListViewController *viewController = (QRAppListViewController *)self.contentViewController;
	[viewController viewWillDisappear];
}

- (void)popoverDidClose:(NSNotification *)notification {
	QRAppListViewController *viewController = (QRAppListViewController *)self.contentViewController;
	[viewController viewDidDisappear];
}

- (void)selectedApp:(QRCachedRunningApplication *)app {
	if ([self.appListDelegate respondsToSelector:@selector(appListPopover:selectedApp:)]) {
		[self.appListDelegate appListPopover:self selectedApp:app];
	}
}

@end
