//
//  AppDelegate.h
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PTKeyComboPanel.h"


#define GlobalHotkeyName @"hotkey"
#define GlobalHotkeyKeyPath @"values.hotkey"

@class QRRadar;

@interface AppDelegate : NSObject <NSApplicationDelegate, PTKeyComboPanelDelegate>

@property (assign) IBOutlet NSMenu *menu;

- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)showDuplicateWindow:(id)sender;

- (IBAction)newBug:(id)sender;
- (IBAction)bugWindowControllerSubmissionComplete:(id)sender;
- (IBAction)activateAndShowAbout:(id)sender;
- (void)newBugWithRadar:(QRRadar*)radar;
@end
