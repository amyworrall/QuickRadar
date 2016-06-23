//
//  BlockBasedURLConnection.m
//  QuickRadar
//
//  Created by Amy Worrall on 16/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRURLConnection.h"
#import "NSString+URLEncoding.h"
#import "OrderedDictionary.h"

@interface QRURLConnection()


@end

@implementation QRURLConnection

@synthesize request = _request, postParameters, HTTPPassword, HTTPUsername, useMultipartRatherThanURLEncoded,  cookiesReturned, fieldOrdering;

- (NSData*)fetchSyncWithError:(NSError**)error;
{
	NSMutableURLRequest *request = [self.request mutableCopy];
	
    if (self.customBody)
    {
        [request setHTTPBody:self.customBody];
    }
	else if (self.useMultipartRatherThanURLEncoded && self.postParameters && !self.sendPostParamsAsJSON)
	{
		[request setHTTPMethod:@"POST"];
		
		NSString *boundary = @"----WebKitFormBoundaryDjNJTz928CjLx8fQ";
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
		[request setValue:contentType forHTTPHeaderField:@"Content-type"];
		
		NSMutableData *postBody = [NSMutableData data];
		
		[postBody appendData:[[NSString stringWithFormat:@"--%@", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
			
		
		if (!self.fieldOrdering)
		{
			self.fieldOrdering = [self.postParameters allKeys];
		}

		
		
		for (NSString *key in self.fieldOrdering)
		{
			id object = (self.postParameters)[key];
			if ([object isKindOfClass:[NSString class]])
			{
				[postBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
				
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[(self.postParameters)[key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
			}
			else if ([object isKindOfClass:[NSData class]])
			{
				[postBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
				
				NSString *filename = self.postParametersFilenames[key] ?: @"";
				
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, filename] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:(self.postParameters)[key]];
				[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
			}
		}
		
		
		
		[postBody appendData:[@"--\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		
			
			
			NSString* postLength = [NSString stringWithFormat:@"%lu", [postBody length]];
			[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
			
			[request setHTTPBody: postBody];

	}
	else if (self.postParameters && [request.HTTPMethod isEqualToString:@"POST"] && !self.sendPostParamsAsJSON)
	{
		NSMutableString *ps = [NSMutableString string];
		
		BOOL first = YES;
		for (NSString *key in self.postParameters)
		{
			[ps appendFormat:@"%@%@=%@", (first==YES) ? @"" : @"&", key, [[(self.postParameters)[key] description] urlEncodeUsingEncoding:NSUTF8StringEncoding]];
			first=NO;
		}
		
		NSData* postVariables = [ps dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
		NSString* postLength = [NSString stringWithFormat:@"%lu", [postVariables length]];
		
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody: postVariables];

//		NSLog(@"Headers %@", request.allHTTPHeaderFields);
//		NSLog(@"Body %@", ps);
//		
//		NSLog(@"Req %@", request);
	}
	else if (self.postParameters && self.sendPostParamsAsJSON)
	{
		NSData *data = [NSJSONSerialization dataWithJSONObject:self.postParameters options:0 error:error];
		
		if (data)
		{
			[request setValue:[NSString stringWithFormat:@"%lu", data.length] forHTTPHeaderField:@"Content-Length"];
			[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
			request.HTTPBody = data;
		}
	}
	
	if (self.addRadarSpoofingHeaders)
	{
        
        
        if ([request valueForHTTPHeaderField:@"Accept"].length == 0)
        {
            [request addValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
        }
		[request addValue:[NSString stringWithFormat:@"https://%@", request.URL.host] forHTTPHeaderField:@"Origin"];
		[request addValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1" forHTTPHeaderField:@"User-Agent"];
		[request addValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
		[request addValue:@"en-us" forHTTPHeaderField:@"Accept-Language"];
	}
    
//    NSLog(@"Request headers: %@", request.allHTTPHeaderFields);
    
    NSDictionary *existingHeaders = request.allHTTPHeaderFields;
    OrderedDictionary *orderedDict = [[OrderedDictionary alloc] init];

    if (existingHeaders[@"User-Agent"]) [orderedDict setObject:existingHeaders[@"User-Agent"] forKey:@"User-Agent"];
    if (existingHeaders[@"Content-Length"]) [orderedDict setObject:existingHeaders[@"Content-Length"] forKey:@"Content-Length"];
    if (existingHeaders[@"Accept"]) [orderedDict setObject:existingHeaders[@"Accept"] forKey:@"Accept"];
    if (existingHeaders[@"Origin"]) [orderedDict setObject:existingHeaders[@"Origin"] forKey:@"Origin"];
    if (existingHeaders[@"Content-Type"]) [orderedDict setObject:existingHeaders[@"Content-Type"] forKey:@"Content-Type"];
    if (existingHeaders[@"Referer"]) [orderedDict setObject:existingHeaders[@"Referer"] forKey:@"Referer"];
    if (existingHeaders[@"Accept-Language"]) [orderedDict setObject:existingHeaders[@"Accept-Language"] forKey:@"Accept-Language"];
    if (existingHeaders[@"Accept-Encoding"]) [orderedDict setObject:existingHeaders[@"Accept-Encoding"] forKey:@"Accept-Encoding"];
    if (existingHeaders[@"Cookie"]) [orderedDict setObject:existingHeaders[@"Cookie"] forKey:@"Cookie"];
    if (existingHeaders[@"Connection"]) [orderedDict setObject:existingHeaders[@"Connection"] forKey:@"Connection"];
    if (existingHeaders[@"Proxy-Connection"]) [orderedDict setObject:existingHeaders[@"Proxy-Connection"] forKey:@"Proxy-Connection"];
    
    NSArray *allKeys = [orderedDict allKeys];
    for (NSString *key in existingHeaders)
    {
        if (![allKeys containsObject:key])
        {
            [orderedDict setObject:[existingHeaders objectForKey:key] forKey:key];
        }
    }

    [request setAllHTTPHeaderFields:orderedDict];
    
//    NSLog(@"Request headers2: %@", request.allHTTPHeaderFields);
    
	NSHTTPURLResponse *resp;
	NSData *d =  [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:error];
	
	self.cookiesReturned = [NSHTTPCookie cookiesWithResponseHeaderFields:[resp allHeaderFields] forURL:resp.URL];
	
	return d;
}

@end
