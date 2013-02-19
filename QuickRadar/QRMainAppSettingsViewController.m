//
//  QBMainAppSettingsViewController.m
//  QuickRadar
//
//  Created by Amy Worrall on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRMainAppSettingsViewController.h"
#import "PTHotKeyLib.h"
#import "AppDelegate.h"

@interface QRMainAppSettingsViewController ()

@end

@implementation QRMainAppSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (nibNameOrNil.length == 0)
	{
		nibNameOrNil = @"QRMainAppSettingsViewController";
	}
	
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}




- (IBAction)changeHotKey:(id)sender 
{
	id hotkey = [[PTHotKeyCenter sharedCenter] hotKeyForName:GlobalHotkeyName];
	[[PTKeyComboPanel sharedPanel] showSheetForHotkey:hotkey forWindow:self.view.window modalDelegate:self];
}

- (void)keyComboPanelEnded:(PTKeyComboPanel*)panel {
	[[NSUserDefaults standardUserDefaults] setObject:[[panel keyCombo] plistRepresentation] forKey:GlobalHotkeyName];
}


@end
