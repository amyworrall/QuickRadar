//
//  QRConfigListPopover.h
//  QuickRadar
//
//  Created by Michael Herring on 2/24/13.
//
//

#import <Cocoa/Cocoa.h>
#import "QRCachedRadarConfiguration.h"

@protocol QRConfigListPopoverDelegate;

@interface QRConfigListPopover : NSPopover <NSPopoverDelegate>

@property (nonatomic, unsafe_unretained) IBOutlet NSObject<QRConfigListPopoverDelegate> *configListDelegate;

- (void)selectedConfig:(QRCachedRadarConfiguration*)aConfig;
- (void)clearConfigurationSelection;

@end


@protocol QRConfigListPopoverDelegate <NSObject>

- (void)configListPopover:(QRConfigListPopover *)popover selectedConfig:(QRCachedRadarConfiguration*)config;

@end
