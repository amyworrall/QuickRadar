//
//  QRAppListPopover.h
//  RunningApps
//
//  Created by Balázs Faludi on 16.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QRCachedRunningApplication;
@protocol QRAppListPopoverDelegate;


@interface QRAppListPopover : NSPopover <NSPopoverDelegate>

@property (nonatomic, unsafe_unretained) IBOutlet NSObject<QRAppListPopoverDelegate> *appListDelegate;

@end


@protocol QRAppListPopoverDelegate <NSObject>

- (void)appListPopover:(QRAppListPopover *)popover selectedApp:(QRCachedRunningApplication *)app;

@end