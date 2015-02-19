//
//  QRMainAppSettingsViewController.m
//  QuickRadar
//
//  Created by Amy Worrall on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRMainAppSettingsViewController.h"
#import "AppDelegate.h"
#import "SRCommon.h"
#import "SGHotKeyCenter.h"
#import "SGHotKey.h"

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

- (void)configureRecorderControl:(SRRecorderControl *)recorderControl withHotKeyIdentifier:(NSString *)identifier
{
    SGHotKeyCenter *hotKeyCenter = [SGHotKeyCenter sharedCenter];
    SGHotKey *hotKey = [hotKeyCenter hotKeyWithIdentifier:identifier];
    if (hotKey) {
        KeyCombo keyCombo;
        keyCombo.code = hotKey.keyCombo.keyCode;
        keyCombo.flags = [recorderControl carbonToCocoaFlags:hotKey.keyCombo.modifiers];
        [recorderControl setAllowsKeyOnly:YES escapeKeysRecord:NO];
        [recorderControl setKeyCombo:keyCombo];
        [recorderControl setNeedsDisplay:YES];
    }
    [recorderControl setDelegate:self];
    [recorderControl setCanCaptureGlobalHotKeys:YES];
}

- (void)awakeFromNib
{
    [self configureRecorderControl:self.hotkeyRecorderControl withHotKeyIdentifier:GlobalHotkeyName];
}


#pragma mark SRRecorderControl delegate

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
    // NOTE: changes to the following actions must also be done in AppDelegate -applicationDidFinishLaunching:
    
    NSString *hotKeyIdentifier = nil;
    SEL action = NULL;
    if (aRecorder == self.hotkeyRecorderControl) {
        hotKeyIdentifier = GlobalHotkeyName;
        action = @selector(hitHotKey:);
    }
    
    if (hotKeyIdentifier) {
        SGHotKeyCenter *hotKeyCenter = [SGHotKeyCenter sharedCenter];
        SGHotKey *hotKey = [hotKeyCenter hotKeyWithIdentifier:hotKeyIdentifier];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        // remove any existing hot key
        if (hotKey) {
            [hotKeyCenter unregisterHotKey:hotKey];
            [userDefaults removeObjectForKey:hotKeyIdentifier];
        }
        
        SGKeyCombo *keyCombo = [SGKeyCombo keyComboWithKeyCode:newKeyCombo.code modifiers:[aRecorder cocoaToCarbonFlags:newKeyCombo.flags]];
        if (newKeyCombo.code != ShortcutRecorderEmptyCode) {
            // create a new hot key
            hotKey = [[SGHotKey alloc] initWithIdentifier:hotKeyIdentifier keyCombo:keyCombo];
            [hotKey setTarget:nil]; // send to first responder
            [hotKey setAction:action];
            [[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
        }
        [userDefaults setObject:[keyCombo plistRepresentation] forKey:hotKeyIdentifier];
        
        [userDefaults synchronize];
    }
}

@end
