//
//  QRAppListManager.m
//  RunningApps
//
//  Created by Balázs Faludi on 16.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//

#import "QRAppListManager.h"
#import "QRCachedRunningApplication.h"

#define kQRAppListCacheFolder @"RunningApps"

#define kQRAppListApplePrefix @"com.apple"

@interface QRAppListManager ()
@property (nonatomic, readwrite) NSMutableArray *appList;
@end


@implementation QRAppListManager

@synthesize categories = _categories;

#pragma mark -
#pragma mark Initialization & Destruction

+ (QRAppListManager *)sharedManager
{
    static QRAppListManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[QRAppListManager alloc] init];
        /* Do any other initialisation stuff here */
    });
    return sharedManager;
}

- (id)init
{
    self = [super init];
    if (self) {
		
		// Observe changes to the active application. We need this to sort the app list accordingly.
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(didActivateApplication:)
																   name:NSWorkspaceDidActivateApplicationNotification object:nil];
		
		// Try to load any cached list, otherwise start with empty list.
		self.appList = [NSMutableArray arrayWithCapacity:15];
		NSArray *loadedList = [self loadList];
		if (loadedList) {
			[self.appList addObjectsFromArray:loadedList];
		}
    }
    return self;
}

#pragma mark -
#pragma mark List Management

- (void)addApp:(QRCachedRunningApplication *)app {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
	[userInfo setObject:app forKey:kQRAppListNotificationAppKey];
	if ([self.appList containsObject:app]) {
		NSInteger oldIndex = [self.appList indexOfObject:app];
		[userInfo setObject:@(oldIndex) forKey:kQRAppListNotificationOldIndexKey];
		QRCachedRunningApplication *existingApp = self.appList[oldIndex];
		[self.appList removeObjectAtIndex:oldIndex];
		[self.appList insertObject:existingApp atIndex:0];
	} else {
		[self.appList insertObject:app atIndex:0];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kQRAppListUpdatesNotification object:self userInfo:userInfo];
}

- (void)didActivateApplication:(NSNotification *)notification {
	// When an app is activated, put it on top of our list (except if it's QuickRadar) and post a notification, so that any
	// currently visible app list GUI can update itself.
	NSRunningApplication *app =  notification.userInfo[NSWorkspaceApplicationKey];
	QRCachedRunningApplication *cachedApp = [[QRCachedRunningApplication alloc] initWithRunningApplication:app];
	if (![[NSRunningApplication currentApplication] isEqual:app] /*&& ![app.bundleIdentifier hasSuffix:@"Xcode"]*/) {
		
		BOOL onlyAppleApps = ![[NSUserDefaults standardUserDefaults] boolForKey:@"QRAppListShowAllApps"];
		if (!onlyAppleApps || [app.bundleIdentifier hasPrefix:kQRAppListApplePrefix]) {
			[self addApp:cachedApp];
		}
	}
}

- (NSString *)cacheFolder {
	NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
	if (cachePath) {
		NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
		cachePath = [cachePath stringByAppendingPathComponent:bundleName];
		cachePath = [cachePath stringByAppendingPathComponent:kQRAppListCacheFolder];
		[[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
		return cachePath;
	}
	return nil;
}

- (void)saveList {
	NSString *plistPath = [[self cacheFolder] stringByAppendingPathComponent:@"AppList.plist"];
	[NSKeyedArchiver archiveRootObject:self.appList toFile:plistPath];
}

- (NSArray *)loadList {
	NSString *plistPath = [[self cacheFolder] stringByAppendingPathComponent:@"AppList.plist"];
	return [NSKeyedUnarchiver unarchiveObjectWithFile:plistPath];
}

#pragma mark -
#pragma mark Categories

- (NSDictionary *)categories {
	if (!_categories) {
		_categories = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ProductCategories" ofType:@"plist"]];
	}
	return _categories;
}

@end
