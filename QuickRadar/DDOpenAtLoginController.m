//
// Created 2013 Dominik Pich
// Some rights reserved.
//

#import "DDOpenAtLoginController.h"
#import <CoreServices/CoreServices.h>

@implementation DDOpenAtLoginController {
    LSSharedFileListRef _sharedFileList;
}

NSArray* SDSharedFileArray(LSSharedFileListRef list);
void SDAppDelegateSharedFileListObservance(LSSharedFileListRef inList, void *context);

- (void)setAppStartsAtLogin:(NSNumber *)numberForAppStartsAtLogin {
    [self willChangeValueForKey:@"appStartsAtLogin"];
    BOOL appStartsAtLogin = numberForAppStartsAtLogin.boolValue;
	
	if (appStartsAtLogin) {
		NSString *appPath = [[NSBundle mainBundle] bundlePath];
		CFURLRef appURL = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
		LSSharedFileListItemRef result = LSSharedFileListInsertItemURL(self.sharedFileList, kLSSharedFileListItemLast, NULL, NULL, appURL, NULL, NULL);
		CFRelease(result);
	}
	else {
		NSArray *array = SDSharedFileArray(self.sharedFileList);
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
		for (id item in array) {
			LSSharedFileListItemRef fileItem = (__bridge LSSharedFileListItemRef)item;
			CFURLRef cfurl = NULL;
            
			if (LSSharedFileListItemResolve(fileItem, 0, &cfurl, NULL) == noErr) {
                NSURL *url = (__bridge_transfer NSURL*)cfurl;
				if ([url.path isEqualToString: bundlePath]) {
					LSSharedFileListItemRemove(self.sharedFileList, fileItem);
                }
			}
		}
	}
    [self didChangeValueForKey:@"appStartsAtLogin"];
}

- (NSNumber*) appStartsAtLogin {
	BOOL appInLoginItems = NO;
	
	NSArray *array = SDSharedFileArray(self.sharedFileList);
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	for (id item in array) {
        LSSharedFileListItemRef listItem = (__bridge LSSharedFileListItemRef)item;
		CFURLRef cfurl = NULL;
        
		if (LSSharedFileListItemResolve(listItem, 0, &cfurl, NULL) == noErr) {
            NSURL *url = (__bridge_transfer NSURL*)cfurl;
			if ([url.path isEqualToString: bundlePath]) {
                appInLoginItems = YES;
                break;
            }
		}
	}
	
	return @(appInLoginItems);
}

- (LSSharedFileListRef) sharedFileList {
    if(!_sharedFileList) {
        _sharedFileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        LSSharedFileListAddObserver(_sharedFileList, CFRunLoopGetMain(), kCFRunLoopDefaultMode, SDAppDelegateSharedFileListObservance, (__bridge void*)self);
    }
    return _sharedFileList;
}

#pragma mark c

NSArray* SDSharedFileArray(LSSharedFileListRef list) {
	UInt32 seed;
	return (__bridge_transfer NSArray*)LSSharedFileListCopySnapshot(list, &seed);
}

void SDAppDelegateSharedFileListObservance(LSSharedFileListRef inList, void *context) {
    DDOpenAtLoginController *controller = (__bridge DDOpenAtLoginController*)context;
	[controller willChangeValueForKey:@"appStartsAtLogin"];
    [controller didChangeValueForKey:@"appStartsAtLogin"];
}

@end
