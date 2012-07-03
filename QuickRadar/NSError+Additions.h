//
//  NSError+Additions.h
//  QuickRadar
//
//  Created by Amy Worrall on 03/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define QRErrorDomain @"QRErrorDomain"
#define QRErrorCodeAuthenticationError 1

@interface NSError (Additions)

+ (NSError*)authenticationErrorWithServiceIdentifier:(NSString*)serviceIdentifier underlyingError:(NSError*)error;

@end
