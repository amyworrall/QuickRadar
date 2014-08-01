//
//  QRAppListViewController.m
//  RunningApps
//
//  Created by Balázs Faludi on 15.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//

#import "QRAppListViewController.h"
#import "QRAppListManager.h"
#import "QRCachedRunningApplication.h"
#import "QRAppListPopover.h"
#import "QRAppListTableCellView.h"

#define kQRAppListMaxHeight 400.0

#define kQRAppListHeaderHeight 35.0f
#define kQRAppListFooterHeight 45.0f

static NSString * const QRAppListHeaderItem = @"Header";
static NSString * const QRAppListFooterItem = @"Footer";

@interface QRAppListPopover ()
- (void)selectedApp:(QRCachedRunningApplication *)app;
@end


@interface QRAppListViewController ()
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSScrollView *scrollView;
@end


@implementation QRAppListViewController
@synthesize scrollView;

#pragma mark -
#pragma mark Convenience Methods

- (void)enableScroller {
	self.scrollView.hasVerticalScroller = YES;
}

- (void)temporarlyDisableScroller {
	self.scrollView.hasVerticalScroller = NO;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(enableScroller) object:nil];
	[self performSelector:@selector(enableScroller) withObject:nil afterDelay:0.3f];
}

- (void)awakeFromNib {
    self.outlineView.target = self;
    self.outlineView.action = @selector(appSelected:);
}

#pragma mark -
#pragma mark Lifecycle

- (void)viewWillAppear {
	[self reloadList];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidUpdateAppList:)
												 name:kQRAppListUpdatesNotification object:nil];
}

- (void)viewDidAppear {
	[self updateHeight];
}

- (void)viewWillDisappear {
	
}

- (void)viewDidDisappear {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kQRAppListUpdatesNotification object:nil];
}

#pragma mark -
#pragma mark The List

- (void)updateHeight {
	CGFloat height = [QRAppListManager sharedManager].appList.count * self.outlineView.rowHeight
						+ kQRAppListHeaderHeight + kQRAppListFooterHeight;
	height = MIN(kQRAppListMaxHeight, height);
	[self temporarlyDisableScroller];
	self.popover.contentSize = NSMakeSize(self.popover.contentSize.width, height);
}

- (void)reloadList {
	[self updateHeight];
	[self.outlineView reloadData];
}

// If appsOnly is YES, return nil for indexes correlating to non-app UI rows
- (id)listItemAtIndex:(NSInteger)index appsOnly:(BOOL)appsOnly {
	id foundItem = nil;
    NSArray *appList = [QRAppListManager sharedManager].appList;
    NSInteger appListCount = appList.count;

	// Special indexes 0 and appListCount + 1 always correlate
	// to the non-app header and footer items, but when appsOnly
	// is YES we guarantee the caller we will return nil for these
	// items.
	if (index == 0) {
		foundItem = appsOnly ? nil : QRAppListHeaderItem;
	}
	else if ((index == appListCount + 1) && !appsOnly) {
		foundItem = appsOnly ? nil : QRAppListFooterItem;
    }
	else {
		// Otherwise adjust the index to accommodate the non-app items,
		// in this case that is solved by subtracting 1 to correlate to
		// the "real apps" list.
		NSInteger appIndex = index - 1;
		if (appIndex >= 0 && appIndex < appListCount) {
			foundItem = [QRAppListManager sharedManager].appList[appIndex];
		}
	}

    return foundItem;
}

- (void)appSelected:(NSOutlineView *)outlineView {
    QRCachedRunningApplication *app = [self listItemAtIndex:[self.outlineView selectedRow] appsOnly:YES];
    if (app == nil)
        return;
    [self.popover selectedApp:app];
}

- (void)completeAppListUpdate:(NSNotification *)notification {
	// A little cheesy hardcoding this but it accommodates the fake "header" item
	// as well as the fake Mac OS X item which should probably always be listed first
	// so it doesn't get lost at the bottom just because it's never "active".
	NSInteger newIndex = 2;
	NSNumber *oldIndexNumber = notification.userInfo[kQRAppListNotificationOldIndexKey];
	if (oldIndexNumber) {
		// Have to adjust the old index as advertised by the app list manager
		// to correlate with our index in the view (skip the header)
		NSInteger oldIndex = [oldIndexNumber integerValue] + 1;
		if (oldIndex != newIndex)
		{
			[self.outlineView moveItemAtIndex:oldIndex inParent:nil toIndex:newIndex inParent:nil];
			[self.outlineView scrollRowToVisible:0];
		}
	} else {
		[self.outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:newIndex] inParent:nil withAnimation:NSTableViewAnimationSlideDown];
	}
}

- (void)managerDidUpdateAppList:(NSNotification *)notification {
	[self updateHeight];
	[self completeAppListUpdate:notification];
}

#pragma mark -
#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	return !item ? [QRAppListManager sharedManager].appList.count + 2 : 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return [self listItemAtIndex:index appsOnly:NO];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	return item;
}

#pragma mark -
#pragma mark NSOutlineViewDelegate

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
	if (item == QRAppListHeaderItem) return kQRAppListHeaderHeight;
	if (item == QRAppListFooterItem) return kQRAppListFooterHeight;
	return outlineView.rowHeight;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(NSObject *)item {
    if (item == QRAppListHeaderItem) {
        NSTableCellView *result = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        result.textField.font = [NSFont boldSystemFontOfSize:[NSFont systemFontSize]];
        return result;
    } else if (item == QRAppListFooterItem) {
        NSTableCellView *result = [outlineView makeViewWithIdentifier:@"FooterCell" owner:self];
        return result;
    }
    // Get the app and setup the cell.
    QRCachedRunningApplication *app = (QRCachedRunningApplication *)item;
    QRAppListTableCellView *result = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
    result.appName = app.unlocalizedName;
    result.appVersion = app.versionAndBuild;
    result.appIcon = app.icon;
    result.showsWarning = [app didCrashRecently];
    return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return (item != QRAppListHeaderItem && item != QRAppListFooterItem);
}

@end
