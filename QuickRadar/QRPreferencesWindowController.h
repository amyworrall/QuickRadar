//
//  PreferencesWindowController.h
//  QuickRadar
//
//  Created by Amy Worrall on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QRPreferencesWindowController : NSWindowController

@property (strong) IBOutlet NSBox *contentBox;

@property (strong) NSArray *panes;
@property (strong) IBOutlet NSArrayController *panesArrayController;


@end
