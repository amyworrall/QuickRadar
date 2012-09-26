//
//  QRAppListViewController.h
//  RunningApps
//
//  Created by Balázs Faludi on 15.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QRAppListPopover;

@interface QRAppListViewController : NSViewController <NSOutlineViewDataSource>

@property (nonatomic, weak) IBOutlet QRAppListPopover *popover;

- (void)viewWillAppear;
- (void)viewDidAppear;
- (void)viewWillDisappear;
- (void)viewDidDisappear;

@end
