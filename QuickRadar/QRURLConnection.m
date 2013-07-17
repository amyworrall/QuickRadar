//
//  BlockBasedURLConnection.m
//  QuickRadar
//
//  Created by Amy Worrall on 16/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRURLConnection.h"
#import "NSString+URLEncoding.h"

@interface QRURLConnection()


@end

@implementation QRURLConnection

@synthesize request = _request, postParameters, HTTPPassword, HTTPUsername, useMultipartRatherThanURLEncoded,  cookiesReturned, fieldOrdering;

- (NSData*)fetchSyncWithError:(NSError**)error;
{
	NSMutableURLRequest *request = [self.request mutableCopy];
	
	if (self.useMultipartRatherThanURLEncoded && self.postParameters)
	{
		[request setHTTPMethod:@"POST"];
		
		NSString *boundary = @"----FOO";
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
				
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"\"\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
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
	else if (self.postParameters && [request.HTTPMethod isEqualToString:@"POST"])
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
	
	if (self.addRadarSpoofingHeaders)
	{
		[request addValue:@"https://bugreport.apple.com" forHTTPHeaderField:@"Origin"];
		[request addValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
		[request addValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/534.55.3 (KHTML, like Gecko) Version/5.1.5 Safari/534.55.3" forHTTPHeaderField:@"User-Agent"];
		[request addValue:@"bugreport.apple.com" forHTTPHeaderField:@"Host"];
		[request addValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
		[request addValue:@"en-gb" forHTTPHeaderField:@"Accept-Language"];
	}

	NSHTTPURLResponse *resp;
	NSData *d =  [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:error];
	
	self.cookiesReturned = [NSHTTPCookie cookiesWithResponseHeaderFields:[resp allHeaderFields] forURL:resp.URL];
	
	return d;
}

@end
