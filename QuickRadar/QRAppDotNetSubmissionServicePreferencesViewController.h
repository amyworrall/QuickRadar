//
//  QRAppDotNetSubmissionServicePreferencesViewController.h
//  QuickRadar
//
//  Created by Amy Worrall on 22/08/2012.
//
//

#import <Cocoa/Cocoa.h>

@interface QRAppDotNetSubmissionServicePreferencesViewController : NSViewController

- (IBAction)authorise:(id)sender;
- (IBAction)obtainAccount:(id)sender;

@property (strong) IBOutlet NSButton *authButton;
@property (strong) IBOutlet NSTextField *statusLabel;

@end
