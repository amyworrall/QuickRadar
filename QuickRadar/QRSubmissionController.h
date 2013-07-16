//
//  RadarSubmission.h
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QRRadar;

@interface QRSubmissionController : NSObject



@property (nonatomic, strong) QRRadar *radar;
@property (nonatomic, strong) NSDictionary *requestedOptionalServices;
@property (readonly) CGFloat progress;
@property (readonly) NSString *statusText;
@property (nonatomic, strong) NSWindow *submissionWindow;


- (void)startWithProgressBlock:(void (^)())progressBlock completionBlock:(void (^)(BOOL, NSError *))completionBlock;

@end
