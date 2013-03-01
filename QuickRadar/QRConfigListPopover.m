//
//  QRConfigListPopover.m
//  QuickRadar
//
//  Created by Michael Herring on 2/24/13.
//
//

#import "QRConfigListPopover.h"
#import "QRConfigListViewController.h"
#import "QRConfigListManager.h"

@interface QRConfigListPopover ()

- (void)newConfigsAvailable:(NSNotification*)notification;
- (void)correctPopoverHeight;

@end

@implementation QRConfigListPopover

- (void)correctPopoverHeight {
    CGFloat height = kQRConfigListFooterHeight + kQRConfigListHeaderHeight;
    height += [[[QRConfigListManager sharedManager] availableConfigurations] count] * 35.0f;
    self.contentSize = NSMakeSize(self.contentSize.width, height);
}

- (void)selectedConfig:(QRCachedRadarConfiguration*)aConfig {
    if ([self.configListDelegate respondsToSelector:@selector(configListPopover:selectedConfig:)]) {
		[self.configListDelegate configListPopover:self selectedConfig:aConfig];
	}
}

- (void)popoverWillShow:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newConfigsAvailable:) name:kQRConfigListUpdatedNotificationName object:nil];
    [self correctPopoverHeight];
}

- (void)popoverWillClose:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kQRConfigListUpdatedNotificationName object:nil];
}

- (void)newConfigsAvailable:(NSNotification*)notification {
    QRConfigListViewController *contentVC = (QRConfigListViewController*)[self contentViewController];
    [contentVC.outlineView reloadData];
    [self correctPopoverHeight];
}

- (void)clearConfigurationSelection {
    QRConfigListViewController *contentVC = (QRConfigListViewController*)[self contentViewController];
    [contentVC.outlineView deselectAll:self];
}

@end
