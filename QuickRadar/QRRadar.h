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
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *classification;
@property (nonatomic, copy) NSString *reproducible;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;

// This is the only service-returned property that should be an actual property: this is because it's so commonly used. 
// Others should be set using setValue:forKey:.
@property (nonatomic, assign) NSInteger radarNumber;

@end
