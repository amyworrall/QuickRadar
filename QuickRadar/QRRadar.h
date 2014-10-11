//
//  QRRadar.h
//  QuickRadar
//
//  Created by Amy Worrall on 26/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QRRadar : NSObject

@property (nonatomic, copy) NSString *product;
@property (nonatomic, assign) NSInteger productCode;

@property (nonatomic, copy) NSString *version;

@property (nonatomic, copy) NSString *classification;
@property (nonatomic, assign) NSInteger classificationCode;

@property (nonatomic, copy) NSString *reproducible;
@property (nonatomic, assign) NSInteger reproducibleCode;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;

@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSDate *dateOriginated;

@property (nonatomic, copy) NSString *configurationString;

@property (nonatomic, copy) NSURL *attachmentURL;

@property (nonatomic, assign) NSInteger radarNumber;
@property (nonatomic, assign) NSInteger draftNumber;
@property (nonatomic, assign) BOOL submittedToOpenRadar;

@end
