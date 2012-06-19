//
//  PasswordStoring.m
//  QuickRadar
//
//  Created by Graham Lee on 14/06/2012.
//
//

#import "PasswordStoring.h"
#import <Security/Security.h>

NSString *serverName = @"bugreport.apple.com";

@implementation PasswordStoring
{
    NSUserDefaults *prefs;
}
@synthesize radarPasswordField;

- (void)awakeFromNib
{
    char *passwordBytes = NULL;
    UInt32 passwordLength = 0;
    prefs = [NSUserDefaults standardUserDefaults];
    NSString *username = [prefs objectForKey: @"username"];
    if (!username) return;
    OSStatus keychainResult = SecKeychainFindInternetPassword(NULL,
                                                              (UInt32)[serverName lengthOfBytesUsingEncoding: NSUTF8StringEncoding],
                                                              [serverName cStringUsingEncoding: NSUTF8StringEncoding],
                                                              0,
                                                              NULL,
                                                              (UInt32)[username lengthOfBytesUsingEncoding: NSUTF8StringEncoding],
                                                              [username cStringUsingEncoding: NSUTF8StringEncoding],
                                                              0,
                                                              NULL,
                                                              443,
                                                              kSecProtocolTypeAny,
                                                              kSecAuthenticationTypeAny,
                                                              &passwordLength,
                                                              (void **)&passwordBytes,
                                                              NULL);
    if (keychainResult) { return; };
    NSString *password = [[NSString alloc] initWithBytes:passwordBytes length:passwordLength encoding:NSUTF8StringEncoding];
    SecKeychainItemFreeContent(NULL, passwordBytes);
	
	if (password)
	{
		self.radarPasswordField.stringValue = password;
	}
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSString *username = [prefs objectForKey: @"username"];
    if (!username) return YES;
    const char *passwordBytes = [self.radarPasswordField.stringValue cStringUsingEncoding: NSUTF8StringEncoding];
    UInt32 passwordLength = (UInt32)[self.radarPasswordField.stringValue lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
    if (!passwordLength) return YES;
    
    //find out if the password already exists
    SecKeychainItemRef keychainItem;
    OSStatus keychainFindResult = SecKeychainFindInternetPassword(NULL,
                                                                  (UInt32)[serverName lengthOfBytesUsingEncoding: NSUTF8StringEncoding],
                                                                  [serverName cStringUsingEncoding: NSUTF8StringEncoding],
                                                                  0,
                                                                  NULL,
                                                                  (UInt32)[username lengthOfBytesUsingEncoding: NSUTF8StringEncoding],
                                                                  [username cStringUsingEncoding: NSUTF8StringEncoding],
                                                                  0,
                                                                  NULL,
                                                                  443,
                                                                  kSecProtocolTypeAny,
                                                                  kSecAuthenticationTypeAny,
                                                                  NULL,
                                                                  NULL,
                                                                  &keychainItem);
    OSStatus passwordStoreResult = errSecSuccess;
    if (keychainFindResult == errSecSuccess) {
        passwordStoreResult = SecKeychainItemModifyAttributesAndData(keychainItem, NULL, passwordLength, passwordBytes);
        CFRelease(keychainItem);
    } else {
        passwordStoreResult = SecKeychainAddInternetPassword(NULL,
                                                                 (UInt32)[serverName lengthOfBytesUsingEncoding: NSUTF8StringEncoding],
                                                                 [serverName cStringUsingEncoding: NSUTF8StringEncoding],
                                                                 0,
                                                                 NULL,
                                                                 (UInt32)[username lengthOfBytesUsingEncoding: NSUTF8StringEncoding],
                                                                 [username cStringUsingEncoding: NSUTF8StringEncoding],
                                                                 0,
                                                                 NULL,
                                                                 443,
                                                                 kSecProtocolTypeAny,
                                                                 kSecAuthenticationTypeAny,
                                                                 passwordLength,
                                                                 passwordBytes,
                                                                 NULL);
    }
    if (passwordStoreResult) { NSLog(@"couldn't store password: %d", passwordStoreResult); };
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    [self control:radarPasswordField textShouldEndEditing:nil];
}
@end
