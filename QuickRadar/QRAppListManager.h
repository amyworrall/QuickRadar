//
//  QRAppListManager.h
//  RunningApps
//
//  Created by Balázs Faludi on 16.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kQRAppListUpdatesNotification @"QRAppListUpdatedFirstApp"
#define kQRAppListNotificationAppKey @"QRAppListNotificationAppKey"
#define kQRAppListNotificationOldIndexKey @"QRAppListNotificationOldIndexKey"

@interface QRAppListManager : NSObject

@property (nonatomic, readonly) NSArray *appList;
@property (nonatomic, readonly) NSDictionary *categories;

+ (QRAppListManager *)sharedManager;

- (NSString *)cacheFolder;
- (void)saveList;

@end
