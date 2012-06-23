//
//  PasswordStoring.h
//  QuickRadar
//
//  Created by Graham Lee on 14/06/2012.
//
//

#import <Foundation/Foundation.h>

@interface PasswordStoring : NSObject

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;

- (void)load;
- (BOOL)save;

@end
