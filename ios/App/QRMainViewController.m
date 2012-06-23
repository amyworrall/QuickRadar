//
//  QRMainViewController.m
//  QuickRadar
//
//  Created by Dominik Pich on 23.06.12.
//
//

#import "QRMainViewController.h"
#import "RadarSubmission.h"

@interface QRMainViewController () {
    NSMutableArray *productMenuItems;
    NSMutableArray *classificationMenuItems;
    NSMutableArray *reproducibleMenuItems;
    
    NSArray *menuItems;
    UIButton *menuButton;
}
@end

@implementation QRMainViewController
@synthesize infoButton;

- (void)viewDidLoad
{
    [super viewDidLoad];

	NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
	
	productMenuItems = [NSMutableArray arrayWithCapacity:10];
	classificationMenuItems = [NSMutableArray arrayWithCapacity:10];
	reproducibleMenuItems = [NSMutableArray arrayWithCapacity:10];
	
	for (NSString *str in [config objectForKey:@"products"])
	{
		[productMenuItems addObject:str];
	}
	for (NSString *str in [config objectForKey:@"classifications"])
	{
		[classificationMenuItems addObject:str];
	}
	for (NSString *str in [config objectForKey:@"reproducible"])
	{
		[reproducibleMenuItems addObject:str];
	}

	/*dummy msg*/
    self.productMenu.titleLabel.text = @"Bug Reporter";
    self.classificationMenu.titleLabel.text = @"Feature (New)";
    self.reproducibleMenu.titleLabel.text = @"z";
    self.versionField.text = @"";
    self.titleField.text = @"";
    self.bodyTextView.text = @"";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(QRFlipsideViewController *)controller
{
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];
//    } else {
//        [self.flipsidePopoverController dismissPopoverAnimated:YES];
//    }
}

#pragma mark actions

- (IBAction)closePicker:(id)sender {
    [self.menuPicker setHidden:YES];
    [self.menuToolbar setHidden:YES];
    [self.menuPicker resignFirstResponder];
}

- (IBAction)showPicker:(id)sender {
    if(![sender isKindOfClass:[UIButton class]])
        return;
    
    menuButton = sender;
    [self.menuPicker reloadAllComponents];
    
    NSUInteger row = [menuItems indexOfObject:[menuButton titleForState:UIControlStateNormal]];
    if(row<menuItems.count)
        [self.menuPicker selectRow:row inComponent:1 animated:NO];
    
    [self.menuPicker setHidden:NO];
    [self.menuToolbar setHidden:NO];
    [self.versionField resignFirstResponder];
    [self.titleField resignFirstResponder];
    [self.bodyTextView resignFirstResponder];
    [self.menuPicker becomeFirstResponder];
    
}

- (IBAction)pickProductMenu:(id)sender {
    menuItems = productMenuItems;
    [self showPicker:self.productMenu];
}

- (IBAction)pickClassificationMenu:(id)sender {
    menuItems = classificationMenuItems;
    [self showPicker:self.classificationMenu];
}

- (IBAction)pickReproducibleMenu:(id)sender {
    menuItems = reproducibleMenuItems;
    [self showPicker:self.reproducibleMenu];
}

- (IBAction)showInfo:(id)sender
{
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        QRFlipsideViewController *controller = [[QRFlipsideViewController alloc] initWithNibName:@"QRFlipsideViewController" bundle:nil];
        controller.delegate = self;
        controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:controller animated:YES];
//    } else {
//        if (!self.flipsidePopoverController) {
//            QRFlipsideViewController *controller = [[QRFlipsideViewController alloc] initWithNibName:@"QRFlipsideViewController" bundle:nil];
//            controller.delegate = self;
//            
//            self.flipsidePopoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
//        }
//        if ([self.flipsidePopoverController isPopoverVisible]) {
//            [self.flipsidePopoverController dismissPopoverAnimated:YES];
//        } else {
//            [self.flipsidePopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//        }
//    }
}

- (IBAction)submitRadar:(id)sender {
    //hack to show login details
    NSUserDefaults *    prefs = [NSUserDefaults standardUserDefaults];
    NSString *username = [prefs objectForKey: @"username"];
    if (!username) {
        [self showInfo:nil];
        return;
    }
    
	RadarSubmission *s = [[RadarSubmission alloc] init];
	s.product = [self.productMenu titleForState:UIControlStateNormal];
	s.classification = [self.classificationMenu titleForState:UIControlStateNormal];
	s.reproducible = [self.reproducibleMenu titleForState:UIControlStateNormal];
	s.version = self.versionField.text;
	s.title = self.titleField.text;
	s.body = self.bodyTextView.text;
	
	[self.submitButton setEnabled:NO];
    [self.infoButton setHidden:YES];
	[self.spinner startAnimating];
	
	[s submitWithCompletionBlock:^(BOOL success) 
     {
         if (success && s.radarNumber.intValue > 0)
         {
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Submission Complete" message:[NSString stringWithFormat:@"Bug submitted as number %@.", s.radarNumber] delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil];
             [alert show];

             [self.submitButton setEnabled:YES];
             [self.infoButton setHidden:NO];
             [self.spinner stopAnimating];

             //clear contents
             self.productMenu.titleLabel.text = @"";
             self.classificationMenu.titleLabel.text = @"";
             self.reproducibleMenu.titleLabel.text = @"";
             self.versionField.text = @"";
             self.titleField.text = @"";
             self.bodyTextView.text = @"";
         }
         else 
         {
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Submission Failed" message:@"Bug submission failed" delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil];
             [alert show];
             
             [self.submitButton setEnabled:YES];
             [self.infoButton setHidden:NO];
             [self.spinner stopAnimating];
             
         }
         
     }];
}

#pragma mark PickerView

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return menuItems.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [menuItems objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [menuButton setTitle:[menuItems objectAtIndex:row] forState:UIControlStateNormal];
}


@end