//
//  AppDelegate.m
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "QRRadarWindowController.h"
#import "QRPreferencesWindowController.h"
#import "QRUserDefaultsKeys.h"
#import "QRAppListManager.h"
#import "SRCommon.h"
#import "QRFileDuplicateWindowController.h"
#import "SGHotKeyCenter.h"
#import "SGKeyCombo.h"
#import "SGHotKey.h"

@interface AppDelegate () <NSUserNotificationCenterDelegate>
{
	NSMutableSet *windowControllerStore;
    NSStatusItem *statusItem;
}

@property (strong) QRPreferencesWindowController *preferencesWindowController;
@property (strong) QRFileDuplicateWindowController *duplicatesWindowController;
@property (assign, nonatomic) BOOL applicationHasStarted;

@end



@implementation AppDelegate

@synthesize menu = _menu;
@synthesize preferencesWindowController = _preferencesWindowController;
@synthesize applicationHasStarted = _applicationHasStarted;

+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
	 QRShowInStatusBarKey: @YES,
	 QRShowInDockKey : @NO,
	 QRHandleRdarURLsKey : @(rdarURLsMethodFileDuplicate),
	 QRWindowLevelKey : [NSNumber numberWithInt:NSStatusWindowLevel],
	 QRFontSizeKey : @10,
     
     GlobalHotkeyName : @{ @"keyCode": @49, @"modifiers" : @6400 }
     }];
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    BOOL shouldShowStatusBarItem = [[NSUserDefaults standardUserDefaults] boolForKey:QRShowInStatusBarKey];
 	BOOL shouldShowDockIcon = [[NSUserDefaults standardUserDefaults] boolForKey:QRShowInDockKey];
		
    if (shouldShowStatusBarItem) {
        //setup statusItem
        statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        statusItem.image = [NSImage imageNamed:@"MenubarTemplate"];
        statusItem.highlightMode = YES;
        statusItem.menu = self.menu;
    }
	
	if (shouldShowDockIcon)
	{
		ProcessSerialNumber psn = {0, kCurrentProcess};
		verify_noerr(TransformProcessType(&psn,
										  kProcessTransformToForegroundApplication));
	}


    // NOTE: changes to hot keys must also be done in QRMainAppSettingsViewController -shortcutRecorder:keyComboDidChange:
    [self registerHotKeyWithIdentifier:GlobalHotkeyName action:@selector(hitHotKey:)];
	
	windowControllerStore = [NSMutableSet set];
	
	if (NSClassFromString(@"NSUserNotificationCenter"))
	{
		[[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
	}

	self.preferencesWindowController = [[QRPreferencesWindowController alloc] init];
	self.duplicatesWindowController = [[QRFileDuplicateWindowController alloc] initWithWindowNibName:@"QRFileDuplicateWindow"];

	// Without either of these settings, the app would show no UI on startup. Show prefs window so that people can figure out how to change it back!
	if (!shouldShowDockIcon && !shouldShowStatusBarItem)
	{
		[self.preferencesWindowController showWindow:self];
	}

	
	// Start tracking apps.
	[QRAppListManager sharedManager];
	
	self.applicationHasStarted = YES;

	NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
	[em
	 setEventHandler:self
	 andSelector:@selector(getUrl:withReplyEvent:)
	 forEventClass:kInternetEventClass
	 andEventID:kAEGetURL];
	
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	LSSetDefaultHandlerForURLScheme((CFStringRef)@"rdar", (__bridge CFStringRef)bundleID);
	LSSetDefaultHandlerForURLScheme((CFStringRef)@"quickradar", (__bridge CFStringRef)bundleID);
	
	
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
{
	return (self.applicationHasStarted);
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication;
{
	[self newBug:self];
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[[QRAppListManager sharedManager] saveList];
}

#pragma mark - Auxillary windows

- (IBAction)showPreferencesWindow:(id)sender;
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[self.preferencesWindowController showWindow:self];
}

- (IBAction)showDuplicateWindow:(id)sender;
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[self.duplicatesWindowController showWindow:self];
}

#pragma mark - NSUserNotificationCenter

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
	return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
	NSDictionary *dict = notification.userInfo;

	NSLog(@"Context %@", dict);

	NSString *stringURL = dict[@"URL"];

	if (!stringURL)
		return;

	NSURL *url = [NSURL URLWithString:stringURL];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark Menu Validation

- (NSString *)keyEquivalentForKeyCode:(NSInteger)keyCode
{
    TISInputSourceRef tisSource = TISCopyCurrentKeyboardInputSource();
    if (! tisSource) {
        return nil;
    }
    
    CFDataRef layoutData;
    UInt32 keysDown = 0;
    layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
    
    CFRelease(tisSource);
    
    // For non-unicode layouts such as Chinese, Japanese, and Korean, get the ASCII capable layout
    if (! layoutData) {
        tisSource = TISCopyCurrentASCIICapableKeyboardLayoutInputSource();
        layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
        CFRelease(tisSource);
    }
    
	if (! layoutData) {
		return nil;
	}
    
    const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
    
	UniCharCount length = 4;
	UniCharCount realLength = 0;
    UniChar chars[4];
    
    OSStatus err = UCKeyTranslate(keyLayout,
                         keyCode,
                         kUCKeyActionDisplay,
                         0,
                         LMGetKbdType(),
                         kUCKeyTranslateNoDeadKeysBit,
                         &keysDown,
                         length,
                         &realLength,
                         chars);
    
	if ( err != noErr ) {
		return nil;
	}
	
    return [NSString stringWithCharacters:chars length:1];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL result = YES;
    
    if ([menuItem menu] == _menu) {
        if (menuItem.tag == 10) {
            // update key equivalent with current hotkey
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            
            NSString *keyEquivalent = @"";
            NSUInteger keyEquivalentModifierMask = 0;
            
            id object = [userDefaults objectForKey:GlobalHotkeyName];
            if (object) {
                SGKeyCombo *keyCombo = [[SGKeyCombo alloc] initWithPlistRepresentation:object];
                if (keyCombo && [keyCombo isValidHotKeyCombo]) {
                    NSString *menuKeyEquivalent = [self keyEquivalentForKeyCode:keyCombo.keyCode];
                    if (menuKeyEquivalent) {
                        keyEquivalent = menuKeyEquivalent;
                        keyEquivalentModifierMask = SRCarbonToCocoaFlags(keyCombo.modifiers);
                    }
                }
            }
            
            menuItem.keyEquivalent = keyEquivalent;
            menuItem.keyEquivalentModifierMask = keyEquivalentModifierMask;
        }
    }
    
    return result;
}

#pragma mark IBActions

- (IBAction)activateAndShowAbout:(id)sender;
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:self];
}



- (IBAction)newBug:(id)sender;
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	
    QRRadarWindowController *b = [[QRRadarWindowController alloc] initWithWindowNibName:@"RadarWindow"];
    [windowControllerStore addObject:b];
    [b showWindow:nil];
	
}

- (void)newBugWithRadar:(QRRadar*)radar;
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	
    QRRadarWindowController *b = [[QRRadarWindowController alloc] initWithWindowNibName:@"RadarWindow"];
	[b prepopulateWithRadar:radar];
    [windowControllerStore addObject:b];
    [b showWindow:nil];
	
}


- (IBAction)bugWindowControllerSubmissionComplete:(id)sender
{
	[windowControllerStore removeObject:sender];
}


- (IBAction)goToAppleRadar:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"https://bugreport.apple.com/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)goToOpenRadar:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://openradar.appspot.com/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark Hotkey Support

- (void)registerHotKeyWithIdentifier:(NSString *)identifier action:(SEL)action
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    id object = [userDefaults objectForKey:identifier];
    if (object) {
        SGKeyCombo *keyCombo = [[SGKeyCombo alloc] initWithPlistRepresentation:object];
        if (keyCombo) {
            SGHotKey *hotKey = [[SGHotKey alloc] initWithIdentifier:identifier keyCombo:keyCombo];
            [hotKey setTarget:nil]; // send the action to the first responder
            [hotKey setAction:action];
            [[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
        }
    }
}

- (void)hitHotKey:(id)sender {
    [self newBug:sender];
}

#pragma mark URL handling

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	// Get the URL
	NSString *urlStr = [[event paramDescriptorForKeyword:keyDirectObject]
						stringValue];
	NSURL *url = [NSURL URLWithString:urlStr];
	
	if ([url.scheme isEqualToString:@"rdar"])
	{
		[self handleRdarURL:url];

	}
	else if ([url.scheme isEqualToString:@"quickradar"])
	{
		// TODO: some way of having the service class register a block for its URL handler. This is a quick-and-dirty method in the mean time.
		
		NSString *urlPartStr = [url.absoluteString stringByReplacingOccurrencesOfString:@"quickradar://" withString:@""];
		
		if ([urlPartStr hasPrefix:@"appdotnetauth"])
		{
			NSArray *parts = [url.absoluteString componentsSeparatedByString:@"#"];
			NSString *token = parts[1];
			
			if ([token hasPrefix:@"access_token="])
			{
				token = [token stringByReplacingOccurrencesOfString:@"access_token=" withString:@""];
				[[NSUserDefaults standardUserDefaults] setObject:token forKey:@"appDotNetUserToken"];
			}
			else
			{
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"appDotNetUserToken"];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:@"AppDotNetAuthChangedNotification" object:self];
		}
	}
	
}


- (void)handleRdarURL:(NSURL *)url
{
	// Work out what to do
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSInteger method = [prefs integerForKey:QRHandleRdarURLsKey];
	
	if (method == rdarURLsMethodDoNothing)
	{
		return;
	}
	
	NSString *rdarId = url.host;
	if ([rdarId isEqualToString:@"problem"]) {
		rdarId = url.lastPathComponent;
	}

	
	if (method == rdarURLsMethodFileDuplicate)
	{
		[self.duplicatesWindowController setRadarNumber:rdarId];
		[self showDuplicateWindow:self];
		[self.duplicatesWindowController OK:self];
	}
	
	if (method == rdarURLsMethodOpenRadar)
	{
		NSURL *openRadarURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://openradar.appspot.com/%@", rdarId]];
		[[NSWorkspace sharedWorkspace] openURL:openRadarURL];
	}
	
}

@end
