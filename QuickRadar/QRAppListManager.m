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


@interface QRSystemFakeApplication : NSObject

-(id)	initWithSysVersionDict: (NSDictionary*)inSysVersionDict;

@property (nonatomic,readwrite) NSDictionary*	sysVersionDict;
@property (nonatomic, readonly) NSString *unlocalizedName;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *build;
@property (nonatomic, readonly) NSString *versionAndBuild;
@property (nonatomic, readonly) NSImage *icon;

@end


@implementation QRSystemFakeApplication

-(id)	initWithSysVersionDict: (NSDictionary*)inSysVersionDict
{
	self = [super init];
	if( self )
		self.sysVersionDict = inSysVersionDict;
	
	return self;
}


-(NSString*)	unlocalizedName
{
	return [self.sysVersionDict objectForKey: @"ProductName"];
}

-(NSString*)	name
{
	return [self.sysVersionDict objectForKey: @"ProductName"];
}

-(NSString*)	version
{
	return [self.sysVersionDict objectForKey: @"ProductVersion"];
}

-(NSString*)	build
{
	return [self.sysVersionDict objectForKey: @"ProductBuildVersion"];
}

-(NSString*)	versionAndBuild
{
	return [NSString stringWithFormat: @"%@ (%@)", self.version, self.build];
}

-(NSImage*)	icon
{
	return [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode( 'macs' )];
}


-(BOOL)	didCrashRecently
{
	return NO;
}


- (NSString *)guessCategory
{
	NSString *identifier = @"com.apple.dock";	// Dock is a part of us, so good guess.
	NSDictionary *categories = [[QRAppListManager sharedManager] categories];
	NSEnumerator *enumerator = [categories keyEnumerator];
	NSString *key;
	while ((key = [enumerator nextObject])) {
		NSArray *bundlePrefixes = categories[key];
		for (NSString *prefix in bundlePrefixes) {
			if ([identifier hasPrefix:prefix]) {
				return key;
			}
		}
	}
	return nil;
}

@end


@interface QRAppListManager ()
@property (nonatomic, readwrite) NSMutableArray *internalAppList;
@property (nonatomic, readwrite) QRSystemFakeApplication *systemFakeAppObject;
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
		self.internalAppList = [NSMutableArray arrayWithCapacity:15];
		NSArray *loadedList = [self loadList];
		if (loadedList) {
			for (QRCachedRunningApplication *app in loadedList) {
				if (![self.internalAppList containsObject:app]) {
					[self.internalAppList addObject:app];
				}
			}
		}
		
		NSDictionary	*	sysVersionDict = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
		self.systemFakeAppObject = [[QRSystemFakeApplication alloc] initWithSysVersionDict: sysVersionDict];
    }
    return self;
}

#pragma mark -
#pragma mark List Management

- (void)addApp:(QRCachedRunningApplication *)app {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
	userInfo[kQRAppListNotificationAppKey] = app;
	if ([self.appList containsObject:app]) {
		NSInteger oldIndex = [self.appList indexOfObject:app];
		userInfo[kQRAppListNotificationOldIndexKey] = @(oldIndex);

		// We have to be sure we're working with the internal array's indexing because of a
		// bogus "QRSystemFakeApplication" that is always (?) at index 0 in the accessor-generated
		// self.appList. Move the item from wherever it is now to the beginning of the array.
		NSInteger internalOldIndex = [self.internalAppList indexOfObject:app];
		QRCachedRunningApplication *existingApp = self.internalAppList[internalOldIndex];
		[self.internalAppList removeObjectAtIndex:internalOldIndex];
		[self.internalAppList insertObject:existingApp atIndex:0];
	} else {
		[self.internalAppList insertObject:app atIndex:0];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kQRAppListUpdatesNotification object:self userInfo:userInfo];
}

- (void)didActivateApplication:(NSNotification *)notification {
	// When an app is activated, put it on top of our list (except if it's QuickRadar) and post a notification, so that any
	// currently visible app list GUI can update itself.
	NSRunningApplication *app =  notification.userInfo[NSWorkspaceApplicationKey];
	QRCachedRunningApplication *cachedApp = [[QRCachedRunningApplication alloc] initWithRunningApplication:app];

	BOOL onlyAppleApps = ![[NSUserDefaults standardUserDefaults] boolForKey:@"QRAppListShowAllApps"];
	if (!onlyAppleApps || [app.bundleIdentifier hasPrefix:kQRAppListApplePrefix]) {
		[self addApp:cachedApp];
	}
}

- (NSString *)cacheFolder {
	NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
	if (cachePath) {
		NSString *bundleName = [[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"];
		cachePath = [cachePath stringByAppendingPathComponent:bundleName];
		cachePath = [cachePath stringByAppendingPathComponent:kQRAppListCacheFolder];
		[[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
		return cachePath;
	}
	return nil;
}

- (void)saveList {
	NSString *plistPath = [[self cacheFolder] stringByAppendingPathComponent:@"AppList.plist"];
	[NSKeyedArchiver archiveRootObject:self.internalAppList toFile:plistPath];
}

- (NSArray *)loadList {
	NSString *plistPath = [[self cacheFolder] stringByAppendingPathComponent:@"AppList.plist"];
	NSArray *list = nil;
	@try {
		list = [NSKeyedUnarchiver unarchiveObjectWithFile:plistPath];
	}
	@catch (NSException *exception) {
		NSLog(@"Corrupted app list cache file at %@", plistPath);
	}
	return list;
}


- (NSArray*)appList {
	NSMutableArray	*	apps = [[NSMutableArray alloc] initWithObjects: self.systemFakeAppObject, nil];
	[apps addObjectsFromArray: self.internalAppList];
	return apps;
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
