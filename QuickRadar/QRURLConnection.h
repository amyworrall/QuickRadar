//
//  BlockBasedURLConnection.h
//  QuickRadar
//
//  Created by Amy Worrall on 16/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QRURLConnection : NSObject

@property (strong) NSURLRequest *request;
@property (strong) NSDictionary *postParameters;
@property (strong) NSDictionary *postParametersFilenames;
@property (strong) NSData *customBody;
@property (strong) NSArray *fieldOrdering;
@property (strong) NSString *HTTPUsername;
@property (strong) NSString *HTTPPassword;
@property (nonatomic, strong) NSArray *cookiesReturned;
@property (nonatomic, assign) BOOL addRadarSpoofingHeaders;
@property (nonatomic, assign) BOOL sendPostParamsAsJSON;

@property (assign) BOOL useMultipartRatherThanURLEncoded;

- (NSData*)fetchSyncWithError:(NSError**)error;

//- (NSData*)requestAsyncWithBlock:

@end
