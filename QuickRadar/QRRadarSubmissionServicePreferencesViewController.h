//
//  QRRadarSubmissionServicePreferencesViewController.h
//  QuickRadar
//
//  Created by Amy Worrall on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QRRadarSubmissionServicePreferencesViewController : NSViewController <NSTextFieldDelegate>

@property (nonatomic, weak) IBOutlet NSSecureTextField *radarPasswordField;

@end
