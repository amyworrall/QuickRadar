//
//  AppDelegate.m
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import <Carbon/Carbon.h>
#import "RadarWindowController.h"
#import <Growl/Growl.h>

OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
						 void *userData)
{
	//Do something once the key is pressed
	AppDelegate *d = [[NSApplication sharedApplication] delegate];
	[d newBug:d];
	return noErr;
}



@interface AppDelegate () <GrowlApplicationBridgeDelegate>
{
	NSMutableSet *windowControllerStore;
}
@end




@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
	
	EventHotKeyRef gMyHotKeyRef;
	EventHotKeyID gMyHotKeyID;
	EventTypeSpec eventType;
	eventType.eventClass=kEventClassKeyboard;
	eventType.eventKind=kEventHotKeyPressed;
	
	InstallApplicationEventHandler(&MyHotKeyHandler,1,&eventType,NULL,NULL);
	
	gMyHotKeyID.signature='htk2';
	gMyHotKeyID.id=2;
	
	RegisterEventHotKey(49, cmdKey+controlKey+optionKey, gMyHotKeyID,
						GetApplicationEventTarget(), 0, &gMyHotKeyRef);

	
	
	windowControllerStore = [NSMutableSet set];
	
	[GrowlApplicationBridge setGrowlDelegate:self];

}


- (NSDictionary *) registrationDictionaryForGrowl;
{
	NSArray *notifications = [NSArray arrayWithObjects:@"Submission Complete", @"Submission Failed", nil];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:notifications, GROWL_NOTIFICATIONS_ALL, notifications, GROWL_NOTIFICATIONS_DEFAULT, nil];
	return dict;
}

- (NSString *) applicationNameForGrowl;
{
	return @"QuickRadar";
}

- (void) growlNotificationWasClicked:(id)clickContext;
{
	NSDictionary *dict = (NSDictionary*)clickContext;
	
	NSLog(@"Context %@", dict);
	
	NSString *stringURL = [dict objectForKey:@"URL"];
	
	if (!stringURL)
		return;
	
	NSURL *url = [NSURL URLWithString:stringURL];
	[[NSWorkspace sharedWorkspace] openURL:url];
}



- (IBAction)newBug:(id)sender;
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	
	RadarWindowController *b = [[RadarWindowController alloc] initWithWindowNibName:@"RadarWindow"];
	[[b window] makeKeyAndOrderFront:self];
//	[b focusTextField];
	
	[windowControllerStore addObject:b];

}


- (IBAction)bugWindowControllerSubmissionComplete:(id)sender
{
	[windowControllerStore removeObject:sender];
}



@end
