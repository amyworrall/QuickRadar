//
//  QRAppDelegate.m
//  QuickRadar
//
//  Created by Dominik Pich on 23.06.12.
//
//

#import "QRAppDelegate.h"

#import "QRMainViewController.h"

@implementation QRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.mainViewController = [[QRMainViewController alloc] initWithNibName:@"QRMainViewController_iPhone" bundle:nil];
    } else {
        self.mainViewController = [[QRMainViewController alloc] initWithNibName:@"QRMainViewController_iPhone" /* @"QRMainViewController_iPad"*/ bundle:nil];
    }
    self.window.rootViewController = self.mainViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
