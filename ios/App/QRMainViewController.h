//
//  QRMainViewController.h
//  QuickRadar
//
//  Created by Dominik Pich on 23.06.12.
//
//

#import "QRFlipsideViewController.h"

@interface QRMainViewController : UIViewController <QRFlipsideViewControllerDelegate>

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;

- (IBAction)showInfo:(id)sender;

@end
