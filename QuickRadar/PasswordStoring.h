//
//  PasswordStoring.h
//  QuickRadar
//
//  Created by Graham Lee on 14/06/2012.
//
//

#import <Foundation/Foundation.h>

@interface PasswordStoring : NSObject <NSTextFieldDelegate>

@property (weak, nonatomic) IBOutlet NSSecureTextField *radarPasswordField;

@end
