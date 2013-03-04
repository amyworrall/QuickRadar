//
//  QRRadarSubmissionServicePreferencesViewController.m
//  QuickRadar
//
//  Created by Amy Worrall on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRRadarSubmissionServicePreferencesViewController.h"
#import "PasswordStoring.h"

@interface QRRadarSubmissionServicePreferencesViewController ()

@end

@implementation QRRadarSubmissionServicePreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];
    
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    NSString *radarPassword = [PasswordStoring radarPasswordForAccount:username error:nil];
    if (radarPassword)
    {
        [_radarPasswordField setStringValue:radarPassword];
    }
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSError *error = nil;
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    [PasswordStoring setRadarPassword:_radarPasswordField.stringValue
                             account:username
                                error:&error];
    
    if (error)
    {
        NSLog(@"error %@", error);   
    }
    
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self control:_radarPasswordField textShouldEndEditing:nil];
}

@end
