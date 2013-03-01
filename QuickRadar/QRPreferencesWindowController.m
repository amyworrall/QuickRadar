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

@interface QRPreferencesWindowController () <NSToolbarDelegate>
@property (strong, nonatomic) IBOutlet NSToolbar *toolbar;
@property (strong, nonatomic) NSMutableArray *panes;
@property (assign, nonatomic) NSUInteger index;
@end

@implementation QRPreferencesWindowController
@synthesize toolbar = _toolbar;
@synthesize panes = _panes;
@synthesize index = _index;

- (instancetype)init
{
	self = [super initWithWindowNibName:NSStringFromClass([self class])];
	if (self)
	{
		_panes = [NSMutableArray new];
	}
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.window.title = NSLocalizedString(@"Preferences", @"Preferences Window Title");
	self.toolbar.delegate = self;
	self.toolbar.allowsUserCustomization = NO;
	
	QRMainAppSettingsViewController *mainPrefsVC = [[QRMainAppSettingsViewController alloc] init];
	mainPrefsVC.title = @"Settings";
	mainPrefsVC.representedObject = [NSImage imageNamed:NSImageNameActionTemplate];
	[self qr_addViewController:mainPrefsVC];
	
	// Start the toolbar with a flexible space
	[self.toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:0];
	
	// Now add all the services
	NSDictionary *services = [QRSubmissionService services];
	
	// Special case Apple Radar, so it comes first
	Class radarPrefsVC = [services objectForKey:QRRadarSubmissionServiceIdentifier];
	[self addViewControllerForClass:radarPrefsVC];
	
	// Now do the others
	NSMutableDictionary *nonRadarServices = [services mutableCopy];
	[nonRadarServices removeObjectForKey:QRRadarSubmissionServiceIdentifier];
	
	for (Class ServiceClass in [nonRadarServices allValues])
	{
		[self addViewControllerForClass:ServiceClass];
	}
	
	// And another flexible space at the end
	[self.toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:self.toolbar.items.count];
	
	[self qr_updateUI];
}


- (void)addViewControllerForClass:(Class)ServiceClass
{
	NSString *viewControllerClassName = [ServiceClass macSettingsViewControllerClassName];
	if (viewControllerClassName.length>0)
	{
		Class viewControllerClass = NSClassFromString(viewControllerClassName);
		NSViewController *viewController = [[viewControllerClass alloc] initWithNibName:viewControllerClassName bundle:nil];
		
		viewController.title = [ServiceClass name];
		viewController.representedObject = [ServiceClass settingsIconPlatformAppropriateImage];
		
		[self qr_addViewController:viewController];
	}
}

- (void)qr_addViewController:(NSViewController *)viewController
{
	[self.panes addObject:viewController];
	[self.toolbar insertItemWithItemIdentifier:viewController.title atIndex:[self.toolbar.items count]];
}

- (void)selectItemAtIndex:(NSUInteger)index
{
	self.index = index;
	NSString *selectedIdentifier = [self.toolbar.items[index] itemIdentifier];
	[self.toolbar setSelectedItemIdentifier:selectedIdentifier];
	[self qr_updateUI];
}

- (void)selectItemWithIdentifier:(NSString *)identifier
{
	NSUInteger index = [[self toolbarAllowedItemIdentifiers:self.toolbar] indexOfObject:identifier];
	if (index == NSNotFound)
	{
		return;
	}
	[self selectItemAtIndex:index];
}

- (void)qr_updateUI
{
	NSViewController *controller = self.panes[self.index];
	self.toolbar.selectedItemIdentifier = controller.title;
	self.window.contentView = controller.view;
}

- (NSViewController *)qr_preferenceViewControllerForIdentifier:(NSString *)identifier
{
	NSViewController *preferenceViewController = nil;
	for (NSViewController *viewController in self.panes)
	{
		if ([viewController.title isEqualToString:identifier])
		{
			preferenceViewController = viewController;
			break;
		}
	}
	return preferenceViewController;
}

#pragma mark - NSToolbarDelegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	NSViewController *viewController = [self qr_preferenceViewControllerForIdentifier:itemIdentifier];
	
	[toolbarItem setImage:[viewController representedObject]];
	[toolbarItem setLabel:[viewController title]];
	[toolbarItem setTarget:self];
	[toolbarItem setAction:@selector(qr_toolbarItemSelected:)];
	
	return toolbarItem;
}

- (NSArray *)qr_identifiers
{
	return [self.panes valueForKey:@"title"];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [self qr_identifiers];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [self qr_identifiers];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [self qr_identifiers];
}

#pragma mark - Toolbar Action

- (void)qr_toolbarItemSelected:(NSToolbarItem *)toolbarItem
{
	[self selectItemWithIdentifier:toolbarItem.itemIdentifier];
}

@end
