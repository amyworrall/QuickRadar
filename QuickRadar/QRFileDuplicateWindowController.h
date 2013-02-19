//
//  QRFileDuplicateWindowController.h
//  QuickRadar
//
//  Created by Amy Worrall on 19/02/2013.
//
//

#import <Cocoa/Cocoa.h>

@interface QRFileDuplicateWindowController : NSWindowController

- (IBAction)OK:(id)sender;
- (IBAction)cancel:(id)sender;

@property (nonatomic, strong) IBOutlet NSTextField *textField;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *spinner;

@property (nonatomic, strong) IBOutlet NSButton *cancelButton;
@property (nonatomic, strong) IBOutlet NSButton *okButton;

@end
