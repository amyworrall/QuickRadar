//
//  QRAppDelegate.h
//  QuickRadar
//
//  Created by Dominik Pich on 23.06.12.
//
//

#import <UIKit/UIKit.h>

@class QRMainViewController;

@interface QRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) QRMainViewController *mainViewController;

@end
