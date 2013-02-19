//
//  QRSubmissionService.h
//  QuickRadar
//
//  Created by Amy Worrall on 26/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QRRadar.h"

typedef enum {
	submissionStatusNotStarted,
	submissionStatusInProgress,
	submissionStatusCompleted,
	submissionStatusFailed
} SubmissionStatus;

NSString * const QRRadarSubmissionServiceIdentifier;
NSString * const QROpenRadarSubmissionServiceIdentifier;
NSString * const QRTwitterSubmissionServiceIdentifier;


@interface QRSubmissionService : NSObject

// A dictionary of service classes, keyed by service identifier
+ (NSDictionary *)services;

// A dictionary of service identifiers (keys) to check box strings (values)
+ (NSDictionary *)checkBoxNames;

// Should be called by all subclasses in +initialize.
+ (void)registerService:(Class)service;



/** The following are all things subclasses should override **/

+ (NSString*)identifier;
+ (NSString*)name;

// Set of service identifiers that MUST be completed before this one runs
+ (NSSet*)hardDependencies;

// Set of service identifiers that, if they are present, should be run before this one.
+ (NSSet*)softDependencies;

+ (BOOL)supportedOnMac;
+ (BOOL)supportedOniOS;

+ (NSString*)macSettingsViewControllerClassName;
+ (NSString*)iosSettingsViewControllerClassName;
+ (id)settingsIconPlatformAppropriateImage;

- (SubmissionStatus)submissionStatus;


// Return YES if the requirements for using this service are met (e.g. user has entered username and password in Settings).
// Don't block this method, so don't go and check the username/pass are valid, just return YES if they're present.
+ (BOOL) isAvailable;

// return YES to only activate this service if the user requests it.
+ (BOOL)requireCheckBox;
// A string to display next to the check box in the user interface.
+ (NSString*)checkBoxString;


// returns a float ranging 0-1 indicating progress. Should return 1 when status is complete.
- (CGFloat)progress;

@property (nonatomic, strong) QRRadar *radar;
@property (nonatomic, strong) NSWindow *submissionWindow;

// The method that does the work. Call progressBlock whenever progress has changed. Call completion block on success or failure.
- (void)submitAsyncWithProgressBlock:(void(^)())progressBlock completionBlock:(void(^)(BOOL success, NSError *error))completionBlock;



@end
