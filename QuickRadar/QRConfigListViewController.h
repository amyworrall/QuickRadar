//
//  QRConfigListViewController.h
//  QuickRadar
//
//  Created by Michael Herring on 2/24/13.
//
//

#import <Cocoa/Cocoa.h>
#import "QRConfigListPopover.h"

#define kQRConfigListMaxHeight 400.0
#define kQRConfigListHeaderHeight 40.0f
#define kQRConfigListFooterHeight 45.0f

@interface QRConfigListViewController : NSViewController  <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, strong) IBOutlet QRConfigListPopover *popover;
@property (nonatomic, strong) IBOutlet NSOutlineView *outlineView;

@end
