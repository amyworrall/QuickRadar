//
//  QRFlipsideViewController.m
//  QuickRadar
//
//  Created by Dominik Pich on 23.06.12.
//
//

#import "QRFlipsideViewController.h"
#import "PasswordStoring.h"

@interface QRFlipsideViewController ()

@end

@implementation QRFlipsideViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    PasswordStoring *store = [[PasswordStoring alloc] init];
    [store load];
    self.radarUsernameField.text = store.username;
    self.radarPasswordField.text = store.password;
    
    id u = [[NSBundle mainBundle] URLForResource:@"Credits" withExtension:@"html"];
    id r = [NSURLRequest requestWithURL:u];
    [self.aboutWebview loadRequest:r];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//    } else {
//        return YES;
//    }
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    PasswordStoring *store = [[PasswordStoring alloc] init];
    store.username = self.radarUsernameField.text;
    store.password = self.radarPasswordField.text;
    [store save];
    [self.delegate flipsideViewControllerDidFinish:self];
}

@end
