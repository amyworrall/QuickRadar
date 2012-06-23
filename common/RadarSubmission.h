//
//  RadarSubmission.h
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadarSubmission : NSObject

@property (nonatomic, copy) NSString *product;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *classification;
@property (nonatomic, copy) NSString *reproducible;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;

@property (nonatomic, copy) NSString *radarNumber;
@property (nonatomic, copy) NSString *radarURL;

- (void)submitWithCompletionBlock:(void(^)(BOOL success))handler;

@end
