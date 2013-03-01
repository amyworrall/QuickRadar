//
//  RadarWindowController.h
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QRAppListPopover.h"
#import "QRConfigListPopover.h"
#import "QRCachedRadarConfiguration.h"
#import "QRRadar.h"

@interface QRRadarWindowController : NSWindowController <QRAppListPopoverDelegate, QRConfigListPopoverDelegate>

@property (nonatomic, strong) IBOutlet NSPopUpButton *productMenu;
@property (nonatomic, strong) IBOutlet NSPopUpButton *classificationMenu;
@property (nonatomic, strong) IBOutlet NSPopUpButton *reproducibleMenu;
@property (nonatomic, strong) IBOutlet NSTextField *versionField;
@property (nonatomic, strong) IBOutlet NSTextField *configurationField;
@property (nonatomic, strong) IBOutlet NSTextField *titleField;
@property (nonatomic, strong) IBOutlet NSTextView *bodyTextView;
@property (nonatomic, strong) IBOutlet NSButton *openRadarCheckbox;
@property (nonatomic, strong) IBOutlet NSButton *submitButton;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *spinner;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *progressBar;
@property (nonatomic, strong) IBOutlet NSButton *appListButton;
@property (nonatomic, strong) IBOutlet QRAppListPopover *appListPopover;
@property (nonatomic, strong) IBOutlet QRConfigListPopover *configListPopover;
@property (nonatomic, strong) IBOutlet NSButton *configListButton;
@property (nonatomic, strong) IBOutlet NSMatrix *checkboxMatrix;

- (IBAction)showAppList:(id)sender;
- (IBAction)submitRadar:(id)sender;
- (IBAction)showConfigList:(id)sender;

- (void)prepopulateWithApp:(QRCachedRunningApplication *)app;
- (void)prepopulateWithConfig:(QRCachedRadarConfiguration *)config;
- (void)prepopulateWithRadar:(QRRadar *)radar;

@end
