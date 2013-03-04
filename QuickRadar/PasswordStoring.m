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

+ (NSString *)radarPasswordForAccount:(NSString *)account error:(NSError **)error
{
    OSStatus status = QRKeychainErrorBadArguments;
    NSString *password = nil;
    if (account)
    {
        NSMutableDictionary *query = [self queryForAccount:account];
        [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
        [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
        
        CFTypeRef result = NULL;
        status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        if (status == errSecSuccess)
        {
            NSData *data = (__bridge_transfer NSData *)result;
            if ([data length] > 0)
            {
                password = [[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding];
            }
        }
    }
    
    if (status != errSecSuccess && error)
    {
        *error = [self errorWithCode:status];
    }
    
    return password;
}

+ (BOOL)setRadarPassword:(NSString *)password account:(NSString *)account error:(NSError **)error
{
    OSStatus status = QRKeychainErrorBadArguments;
    if (account)
    {
        [self deleteRadarPasswordForAccount:account error:nil];
        
        NSMutableDictionary *query = [self queryForAccount:account];
        [query setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
    
    if (status != errSecSuccess && error)
    {
        *error = [self errorWithCode:status];
    }
    
    return (status == errSecSuccess);
}

+ (BOOL)deleteRadarPasswordForAccount:(NSString *)account error:(NSError **)error
{
    OSStatus status = QRKeychainErrorBadArguments;
    if (account)
    {
        NSMutableDictionary *query = [self queryForAccount:account];
#if TARGET_OS_IPHONE
        status = SecItemDelete((__bridge CFDictionaryRef)query);
#else
        CFTypeRef result = NULL;
        [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnRef];
        status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        if (status == errSecSuccess)
        {
            status = SecKeychainItemDelete((SecKeychainItemRef) result);
            CFRelease(result);
        }
#endif
    }
    
    if (status != errSecSuccess && error)
    {
        *error = [self errorWithCode:status];
    }
    
    return (status == errSecSuccess);
}

#pragma mark - Private

+ (NSMutableDictionary *)queryForAccount:(NSString *)account
{
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithCapacity:3];
    [query setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
    [query setObject:serverName forKey:(__bridge id)kSecAttrServer];
    [query setObject:account forKey:(__bridge id)kSecAttrAccount];
    
    return query;
}

+ (NSError *)errorWithCode:(OSStatus)code
{
    NSString *message = nil;
    switch (code)
    {
        case errSecSuccess: return nil;
        case QRKeychainErrorBadArguments: message = @"Some of the arguments where invaild."; break;
#if TARGET_OS_IPHONE
        case errSecUnimplemented: message = @"Function or operation not implemented."; break;
        case errSecParam: message = @"One or more parameters passed to the function were not valid."; break;
        case errSecAllocate: message = @"Failed to allocate memory."; break;
        case errSecNotAvailable: message = @"No trust results are available."; break;
        case errSecAuthFailed: message = @"Authorization/Authentication failed."; break;
        case errSecDuplicateItem: message = @"The item already exists."; break;
        case errSecItemNotFound: message = @"The item cannot be found."; break;
        case errSecInteractionNotAllowed: message = @"Interaction with the Security Server is not allowed."; break;
        case errSecDecode: message = @"Unable to decode the provided data."; break;
        default: message = @"Unknown error.";
#else
        default: message = (__bridge NSString *)(SecCopyErrorMessageString(code, NULL));
#endif
    }
    
    NSDictionary *userInfo = nil;
    if (message)
    {
        userInfo = @{NSLocalizedDescriptionKey: message};
    }
    
    return [NSError errorWithDomain:@"com.quickradar.QuickRadar"
                               code:code
                           userInfo:userInfo];
}

@end
