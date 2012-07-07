//
//  BlockBasedURLConnection.m
//  QuickRadar
//
//  Created by Amy Worrall on 16/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SuperURLConnection.h"

@interface SuperURLConnection()


@end

@implementation SuperURLConnection

@synthesize request = _request, postParameters, HTTPPassword, HTTPUsername, useMultipartRatherThanURLEncoded, fileParameters, cookiesReturned, fieldOrdering;

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
			
		
		if (!self.fieldOrdering && self.fileParameters)
		{
			self.fieldOrdering = [[self.postParameters allKeys] arrayByAddingObjectsFromArray:[self.fileParameters allKeys]];
		}
		else if (!self.fieldOrdering && !self.fileParameters)
		{
			self.fieldOrdering = [self.postParameters allKeys];
		}

		
		
		for (NSString *key in self.fieldOrdering)
		{
			if ([self.postParameters.allKeys containsObject:key])
			{
				[postBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
				
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[self.postParameters objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
			}
			else if ([self.fileParameters.allKeys containsObject:key])
			{
				[postBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
				
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"\"\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[self.fileParameters objectForKey:key]];
				[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
			}
		}
		
		
		
		[postBody appendData:[@"--\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		
			
#if TARGET_OS_IPHONE
        NSString* postLength = [NSString stringWithFormat:@"%u", [postBody length]];
#else
		NSString* postLength = [NSString stringWithFormat:@"%lu", [postBody length]];
#endif
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
			
			[request setHTTPBody: postBody];

	}
	else if (self.postParameters && [request.HTTPMethod isEqualToString:@"POST"])
	{
		NSMutableString *ps = [NSMutableString string];
		
		BOOL first = YES;
		for (NSString *key in self.postParameters)
		{
			[ps appendFormat:@"%@%@=%@", (first==YES) ? @"" : @"&", key, [[self.postParameters objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			first=NO;
		}
		
		NSData* postVariables = [ps dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
#if TARGET_OS_IPHONE
		NSString* postLength = [NSString stringWithFormat:@"%u", [postVariables length]];
#else
        NSString* postLength = [NSString stringWithFormat:@"%lu", [postVariables length]];
#endif
        
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody: postVariables];

//		NSLog(@"Headers %@", request.allHTTPHeaderFields);
//		NSLog(@"Body %@", ps);
//		
//		NSLog(@"Req %@", request);
	}
	[request addValue:@"https://bugreport.apple.com" forHTTPHeaderField:@"Origin"];
	[request addValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
	[request addValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/534.55.3 (KHTML, like Gecko) Version/5.1.5 Safari/534.55.3" forHTTPHeaderField:@"User-Agent"];
	[request addValue:@"bugreport.apple.com" forHTTPHeaderField:@"Host"];
	[request addValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
	[request addValue:@"en-gb" forHTTPHeaderField:@"Accept-Language"];

//	NSLog(@"Headers %@", request.allHTTPHeaderFields);
//	NSLog(@"Body %@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
	
	NSHTTPURLResponse *resp;
	NSData *d =  [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:error];
	
	self.cookiesReturned = [NSHTTPCookie cookiesWithResponseHeaderFields:[resp allHeaderFields] forURL:resp.URL];
	
	return d;
}

@end
