//
//  AppDelegate.h
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PTKeyComboPanel.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, PTKeyComboPanelDelegate>

@property (assign) IBOutlet NSMenu *menu;
@property (assign) IBOutlet NSWindow *window;

- (IBAction)newBug:(id)sender;
- (IBAction)bugWindowControllerSubmissionComplete:(id)sender;
- (IBAction)activateAndShowAbout:(id)sender;
- (IBAction)activateAndShowLoginDetails:(id)sender;
- (IBAction)activateAndShowHotkeySettings:(id)sender;
@end
