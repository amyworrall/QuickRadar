//
//  QRAppListTableCellView.h
//  RunningApps
//
//  Created by Balázs Faludi on 18.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QRAppListTableCellView : NSTableCellView

@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appVersion;
@property (nonatomic) NSImage *appIcon;
@property (nonatomic) BOOL showsWarning;

@end