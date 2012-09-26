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

//- (void)awakeFromNib {
//	[self reloadList];
//}

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

- (void)completeAppListUpdate:(NSNotification *)notification {
	NSNumber *oldIndexNumber = notification.userInfo[kQRAppListNotificationOldIndexKey];
	if (oldIndexNumber) {
		NSInteger oldIndex = [oldIndexNumber integerValue] + 1;
		[self.outlineView moveItemAtIndex:oldIndex inParent:nil toIndex:1 inParent:nil];
		[self.outlineView scrollRowToVisible:0];
	} else {
		[self.outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:1] inParent:nil withAnimation:NSTableViewAnimationSlideDown];
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
	if (index == 0) return @"Header";
	if (index == [QRAppListManager sharedManager].appList.count + 1) return @"Footer";
	return [QRAppListManager sharedManager].appList[index-1];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	return item;
}

#pragma mark -
#pragma mark NSOutlineViewDelegate

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
	if ([item isEqual:@"Header"]) return kQRAppListHeaderHeight;
	if ([item isEqual:@"Footer"]) return kQRAppListFooterHeight;
	return outlineView.rowHeight;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(NSObject *)item {
    if ([item isKindOfClass:[NSString class]]) {
		if ([((NSString *)item) isEqualToString:@"Header"]) {
			NSTableCellView *result = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
			result.textField.font = [NSFont fontWithName:@"Lucida Grande Bold" size:13.0f];
			return result;
		} else {
			NSTableCellView *result = [outlineView makeViewWithIdentifier:@"FooterCell" owner:self];
			return result;
		}
    } else {
		// Get the app and setup the cell.
		QRCachedRunningApplication *app = (QRCachedRunningApplication *)item;
        QRAppListTableCellView *result = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
		result.appName = app.unlocalizedName;
		result.appVersion = app.versionAndBuild;
		result.appIcon = app.icon;
		result.showsWarning = [app didCrashRecently];
		return result;
    }
    return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	NSInteger index = [self.outlineView selectedRow];
	QRCachedRunningApplication *app = [QRAppListManager sharedManager].appList[index-1];
	[self.popover selectedApp:app];
}

@end
