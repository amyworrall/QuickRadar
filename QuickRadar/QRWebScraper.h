//
//  WebScraper.h
//  QuickRadar
//
//  Created by Amy Worrall on 21/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QRWebScraper : NSObject

// param can be a string or NSData object. The order they're added is the order they'll be in the response.
- (void)addPostParameter:(id)param forKey:(NSString*)key;

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, copy) NSString *HTTPMethod;
@property (nonatomic, assign) BOOL sendMultipartFormData;
@property (nonatomic, strong) QRWebScraper *cookiesSource;
@property (nonatomic, strong) QRWebScraper *referrer;
@property (nonatomic, strong) NSData *returnedData;

/* A synchronous method */
- (BOOL)fetch:(NSError**)error;

- (NSDictionary*)stringValuesForXPathsDictionary:(NSDictionary*)dict error:(NSError**)error;

@end
