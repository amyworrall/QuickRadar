//
//  PasswordStoringWindow.m
//  QuickRadar
//
//  Created by Graham Lee on 14/06/2012.
//
//

#import "PasswordStoring.h"
#import "PasswordStoringWindow.h"
#import <Security/Security.h>

@implementation PasswordStoringWindow
{
    PasswordStoring *store;
}
@synthesize radarUsernameField;
@synthesize radarPasswordField;

- (void)awakeFromNib
{
    store = [[PasswordStoring alloc] init];
    [store load];
    
	if (store.username)
	{
		self.radarUsernameField.stringValue = store.username;
	}
	if (store.password)
	{
		self.radarPasswordField.stringValue = store.password;
	}
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    store.username = self.radarUsernameField.stringValue;
    store.password = self.radarPasswordField.stringValue;
    [store save];
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    [self control:radarPasswordField textShouldEndEditing:nil];
}
@end
