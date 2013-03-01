//
//  QRConfigListViewController.m
//  QuickRadar
//
//  Created by Michael Herring on 2/24/13.
//
//

#import "QRConfigListViewController.h"
#import "QRConfigListTableCellView.h"
#import "QRConfigListManager.h"

@interface QRConfigListViewController () {
    NSObject *_rootItem;
}

@end

@implementation QRConfigListViewController

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return !item?[[[QRConfigListManager sharedManager] availableConfigurations] count] + 2:0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (index == 0) return @"Header";
	if (index == [[[QRConfigListManager sharedManager] availableConfigurations] count] + 1) return @"Footer";
	return [[QRConfigListManager sharedManager] availableConfigurations][index-1];
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
}

#pragma mark -
#pragma mark NSOutlineViewDelegate

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
	if ([item isEqual:@"Header"]) return kQRConfigListHeaderHeight;
	if ([item isEqual:@"Footer"]) return kQRConfigListFooterHeight;
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
		// Get the configuration and setup the cell.
		QRCachedRadarConfiguration *config = (QRCachedRadarConfiguration*)item;
        QRConfigListTableCellView *result = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
		result.textField.stringValue = config.name;
		return result;
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if ([item isKindOfClass:[QRCachedRadarConfiguration class]]) {
        return YES;
    }
    return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	NSInteger index = [self.outlineView selectedRow];
    NSArray * configs = [[QRConfigListManager sharedManager] availableConfigurations];
    if (index < 1 || index > [configs count]) {
        return;
    }
	QRCachedRadarConfiguration *config = configs[index-1];
    [self.popover selectedConfig:config];
    [self.outlineView deselectAll:self];
}


@end
