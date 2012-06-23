//
//  QRFlipsideViewController.h
//  QuickRadar
//
//  Created by Dominik Pich on 23.06.12.
//
//

#import <UIKit/UIKit.h>

@class QRFlipsideViewController;

@protocol QRFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(QRFlipsideViewController *)controller;
@end

@interface QRFlipsideViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *radarUsernameField;
@property (weak, nonatomic) IBOutlet UITextField *radarPasswordField;
@property (weak, nonatomic) IBOutlet UIWebView *aboutWebview;

@property (weak, nonatomic) id <QRFlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end
