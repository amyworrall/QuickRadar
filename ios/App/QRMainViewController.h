//
//  QRMainViewController.h
//  QuickRadar
//
//  Created by Dominik Pich on 23.06.12.
//
//

#import "QRFlipsideViewController.h"

@interface QRMainViewController : UIViewController <QRFlipsideViewControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;

@property (nonatomic, strong) IBOutlet UIPickerView *menuPicker;
@property (nonatomic, strong) IBOutlet UIToolbar *menuToolbar;

@property (nonatomic, strong) IBOutlet UIButton *productMenu;
@property (nonatomic, strong) IBOutlet UIButton *classificationMenu;
@property (nonatomic, strong) IBOutlet UIButton *reproducibleMenu;
@property (nonatomic, strong) IBOutlet UITextField *versionField;
@property (nonatomic, strong) IBOutlet UITextField *titleField;
@property (nonatomic, strong) IBOutlet UITextView *bodyTextView;
@property (nonatomic, strong) IBOutlet UIButton *openRadarCheckbox;
@property (nonatomic, strong) IBOutlet UIButton *submitButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;

- (IBAction)closePicker:(id)sender;
- (IBAction)pickProductMenu:(id)sender;
- (IBAction)pickClassificationMenu:(id)sender;
- (IBAction)pickReproducibleMenu:(id)sender;

- (IBAction)showInfo:(id)sender;
- (IBAction)submitRadar:(id)sender;

@end
