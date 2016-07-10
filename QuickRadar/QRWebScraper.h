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
- (void)addPostParameter:(id)param forKey:(NSString*)key filename:(NSString*)filename;

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, copy) NSString *HTTPMethod;
@property (nonatomic, assign) BOOL sendMultipartFormData;
@property (nonatomic, strong) QRWebScraper *cookiesSource;
@property (nonatomic, strong) id referrer; // can be a QRWebScaper or a string
@property (nonatomic, strong) NSData *returnedData;
@property (nonatomic, strong) NSDictionary *customHeaders;
@property (nonatomic, strong) NSData *customBody;
@property (nonatomic, assign) BOOL shouldParseXML; // defaults to YES

/* A synchronous method */
- (BOOL)fetch:(NSError**)error;

/* Deletes any cookies currently present. Set the URL before invoking this method. */
- (BOOL)deleteCookies;

- (NSDictionary*)stringValuesForXPathsDictionary:(NSDictionary*)dict error:(NSError**)error;

@end
