//
//  PasswordStoring.h
//  QuickRadar
//
//  Created by Graham Lee on 14/06/2012.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    QRKeychainErrorBadArguments = -1001
} QRKeychainErrorCode;

/**
 * Simple wrapper for getting, setting and deleting the password for the radar submission service.
 */

@interface PasswordStoring : NSObject

/**
 * @name Getting Passwords
 */

/**
 * Returns a string containing the radar password, or nil if the keychain doesn't have a password.
 *
 * @param account The account for which to return the corresponding password.
 *
 * @return Returns a string containing the radar password, or nil if the keychain doesn't have a password.
 */
+ (NSString *)radarPasswordForAccount:(NSString *)account error:(NSError **)error;

/**
 * @name Setting Passwords
 */

/**
 * Sets a password in the keychain.
 *
 * @param password The password to store in the keychain.
 * @param account The account for which to set the corresponding password.
 * @param error If setting the password fails upon return contains an error that describes the problem.
 *
 * @return YES on success, or NO on failure.
 */
+ (BOOL)setRadarPassword:(NSString *)password account:(NSString *)account error:(NSError **)error;

/**
 * @name Deleting Passwords
 */

/**
 * Deletes a password in the keychain.
 *
 * @param account The accunt for which to delete the corresponding password.
 * @param error If deleting password fails upon return contains an error that describes the problem.
 *
 * @return YES on success, or NO on failure.
 */
+ (BOOL)deleteRadarPasswordForAccount:(NSString *)account error:(NSError **)error;

@end
