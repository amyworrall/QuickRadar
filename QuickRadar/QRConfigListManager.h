//
//  QRConfigListManager.h
//  QuickRadar
//
//  Created by Michael Herring on 2/24/13.
//
//

#import <Foundation/Foundation.h>

#define kQRConfigListUpdatedNotificationName @"QRConfigListUpdatedNotification"

@interface QRConfigListManager : NSObject

@property (readonly) NSArray *availableConfigurations;

+ (QRConfigListManager *)sharedManager;
- (void)attemptToUpdateConfigurations;

@end
