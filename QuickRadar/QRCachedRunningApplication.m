//
//  QRCachedRunningApplication.m
//  RunningApps
//
//  Created by Balázs Faludi on 16.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//

#import "QRCachedRunningApplication.h"
#import "QRAppListManager.h"

#define kQRCachedAppBundleDisplayName		@"CFBundleDisplayName"
#define kQRCachedAppBundleName				@"CFBundleName"
#define kQRCachedAppShortVersionString		@"CFBundleShortVersionString"
#define kQRCachedAppBundleVersion			@"CFBundleVersion"

#define kQRCachedAppCrashReportSearchPaths	@[@"~/Library/Logs/DiagnosticReports", @"/Library/Logs/DiagnosticReports"]
#define kQRCachedAppCrashReportExtension	@"crash"
#define kQRCachedAppCrashReportMaxAge		(60*15)	// seconds

#define kQRCachedAppXcodeIdentifier			@"com.apple.dt.Xcode"
#define kQRCachedAppXcodeVersionPlist		@"Contents/version.plist"
#define kQRCachedAppXcodeBuildVersion		@"ProductBuildVersion"

@interface QRCachedRunningApplication ()
@property (nonatomic, strong) NSRunningApplication *runningApplication;
@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic) NSString *name;
@end

@implementation QRCachedRunningApplication

#pragma mark - Initialization & Destruction

- (id)initWithRunningApplication:(NSRunningApplication *)app
{
    self = [super init];
    if (self) {
        self.runningApplication = app;
		self.bundle = [NSBundle bundleWithURL:app.bundleURL];
		self.name = app.localizedName;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
		// Load saved bundle URL, get the bundle.
        NSBundle *bundle = nil;
        
		NSURL *bundleURL = [coder decodeObjectForKey:@"BundleURL"];
        if (bundleURL != nil) {
            bundle = [NSBundle bundleWithURL:bundleURL];
            self.bundle = bundle;
        }
		
		// Try to get the the app instance if it's running.
        if (bundle)
        {
            NSArray *possibleApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:self.bundle.bundleIdentifier];
            if (possibleApps.count == 1) {	// If there are more then 1 apps running with the same ID, don't guess, but rather ignore them all.
                self.runningApplication = possibleApps[0];
            }
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.bundle.bundleURL forKey:@"BundleURL"];
}

#pragma mark - Getters

// We have to tell Apple the unlocalized name, but NSRunningApplication doesn't have such a method.
- (NSString *)unlocalizedName {
	if ([self.bundle.bundleIdentifier hasPrefix:@"com.apple.dt.Xcode"]) {
		return [[self.bundle.bundlePath lastPathComponent] stringByDeletingPathExtension];
	}
	NSDictionary *info = self.bundle.infoDictionary;
	if (info) {
		NSString *name = info[kQRCachedAppBundleDisplayName];
		if (name) {return name;}
		name = info[kQRCachedAppBundleName];
		if (name) {return name;}
        name = info[(NSString *)kCFBundleExecutableKey];
        if (name) {return name;}
	}
	return nil;
}

- (NSString *)version {
	// If it's a dev preview version of Xcode, don't return a version, because the name already contains the version.
	if ([self.bundle.bundleIdentifier hasPrefix:@"com.apple.dt.Xcode"]) {
		BOOL dpVersion = [[[self.bundle.bundlePath lastPathComponent] stringByDeletingPathExtension]
						  caseInsensitiveCompare:@"xcode"] != NSOrderedSame;
		if (dpVersion) {
			return nil;
		}
	}
	return self.bundle.infoDictionary[kQRCachedAppShortVersionString];
}

- (NSString *)build {
	// Since Xcode stores it's build number in a separate plist, we want to handle that too...
	if ([self.bundle.bundleIdentifier isEqualToString:kQRCachedAppXcodeIdentifier]) {
		NSString *versionPlistPath = [self.bundle.bundlePath stringByAppendingPathComponent:kQRCachedAppXcodeVersionPlist];
		NSDictionary *versionDict = [NSDictionary dictionaryWithContentsOfFile:versionPlistPath];
		NSString *buildString = versionDict[kQRCachedAppXcodeBuildVersion];
		if (buildString) return buildString;
	}
	return self.bundle.infoDictionary[kQRCachedAppBundleVersion];
}

- (NSString *)versionAndBuild {
	NSString *version = self.version;
	NSString *build = self.build;
	NSString *versionAndBuild = @"";
	if (version) versionAndBuild = version;
	if (build && ![build isEqualToString:version]) versionAndBuild = [versionAndBuild stringByAppendingFormat:@" (%@)", build];
	return [versionAndBuild stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
}

- (NSImage *)icon {
	NSImage *image = self.runningApplication.icon;
	if (!image) {
		// If the app couldn't specify an icon (not running anymore probably), try loading it from disk.
        NSString *bundlePath = self.bundle.bundlePath;
        if (bundlePath == nil)
            return nil;
		image = [[NSWorkspace sharedWorkspace] iconForFile:bundlePath];
	}
	return image;	// Can be nil, if app is not running and no cache available!
}

#pragma mark -
#pragma mark Crash reports

// Eumerate through the crash reports since the reference date and filter them for this app.
// If findAll is NO, it returns as soon as at least one report is found, otherwise it will return all reports since the refDate.
- (NSArray *)crashReportsSince:(NSDate *)referenceDate findAll:(BOOL)findAll {
    if (self.bundle == nil)
        return nil;

	NSMutableArray *reports = [NSMutableArray arrayWithCapacity:3];
	for (NSString *aPath in kQRCachedAppCrashReportSearchPaths) {
		NSString *searchPath = [aPath stringByExpandingTildeInPath];
		NSFileManager *manager = [NSFileManager defaultManager];
		NSDirectoryEnumerator *enumerator = [manager enumeratorAtURL:[NSURL fileURLWithPath:searchPath]
										  includingPropertiesForKeys:@[NSURLCreationDateKey]
															 options:0 errorHandler:^BOOL(NSURL *url, NSError *error) {return YES;}];
		for (NSURL *URL in enumerator) {
			BOOL isCrashFile = [[URL pathExtension] isEqualToString:@"crash"];
			NSString *appID = [[self.bundle.bundleIdentifier componentsSeparatedByString:@"."] lastObject];
			NSString *lol = [URL lastPathComponent];
			BOOL isRightApp = [lol hasPrefix:appID];
			if (isCrashFile && isRightApp) {
				NSDate *creationDate;
				if ([URL getResourceValue:&creationDate forKey:NSURLCreationDateKey error:nil]) {
					if ([referenceDate compare:creationDate] == NSOrderedAscending) {
						if (findAll) {
							[reports addObject:[URL path]];
						} else {
							return @[[URL path]];
						}
					}
				}
			}
		}
	}
	return [NSArray arrayWithArray:reports];
}

- (NSArray *)findCrashReports {
	return [self crashReportsSince:[NSDate distantPast] findAll:YES];
}

- (BOOL)didCrashRecently {
	NSDate *refDate = [NSDate dateWithTimeIntervalSinceNow:-kQRCachedAppCrashReportMaxAge];
	return [self crashReportsSince:refDate findAll:NO].count > 0;
}

#pragma mark -
#pragma mark Product Category

// Do some dirty, unflexible guesswork about the app's product category.
- (NSString *)guessCategory {
	NSString *identifier = self.bundle.bundleIdentifier;
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

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[self class]]) {return NO;}
	BOOL isEqual = [self.bundle.bundleURL isEqual:((QRCachedRunningApplication *)object).bundle.bundleURL];
	return isEqual;
}

@end
