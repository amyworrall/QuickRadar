//
//  PasswordStoring.m
//  QuickRadar
//
//  Created by Graham Lee on 14/06/2012.
//
//

#import "PasswordStoring.h"
#import <Security/Security.h>
#import "PDKeychainBindingsController.h"

NSString *serverName = @"bugreport.apple.com";

@implementation PasswordStoring

@synthesize username=_username;
@synthesize password=_password;

- (void)load
{
    //user
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey: @"username"];
    if (!username) return;
    self.username = username;
    
    //password
    NSString *password = [[PDKeychainBindingsController sharedKeychainBindingsController] stringForKey:@"password"
                          ];
    if (!password) return;
    self.password = password;
}

- (BOOL)save
{
    NSString *username = self.username;
    if (!username.length)
        return NO;
    
    NSString *password = self.password;
    if (!password.length)
        return NO;

    //user
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"username"];
    
    //password
    [[PDKeychainBindingsController sharedKeychainBindingsController] storeString:password forKey:@"password"];
    
    return YES;
}

@end
