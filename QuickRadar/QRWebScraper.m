//
//  WebScraper.m
//  QuickRadar
//
//  Created by Amy Worrall on 21/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRWebScraper.h"
#import "QRURLConnection.h"
#import "NSXMLNode+Additions.h"

@interface QRWebScraper ()

@property (nonatomic, strong) NSMutableArray *postParamsOrder;
@property (nonatomic, strong) NSMutableDictionary *postParamsKeyValues;

@property (nonatomic, strong) NSArray *cookiesReturned;
@property (nonatomic, strong) NSXMLDocument *xmlDocument;

@end

@implementation QRWebScraper

@synthesize URL = _URL;
@synthesize cookiesSource = _cookiesSource;
@synthesize referrer = _referrer;
@synthesize HTTPMethod = _HTTPMethod;
@synthesize sendMultipartFormData = _sendMultipartFormData;

@synthesize postParamsOrder = _postParamsOrder;
@synthesize postParamsKeyValues = _postParamsKeyValues;

@synthesize returnedData = _returnedData;
@synthesize cookiesReturned = _cookiesReturned;
@synthesize xmlDocument = _xmlDocument;


- (void)addPostParameter:(id)param forKey:(NSString*)key;
{
	if (!self.postParamsKeyValues)
	{
		self.postParamsKeyValues = [NSMutableDictionary dictionary];
	}
	
	if (!self.postParamsOrder)
	{
		self.postParamsOrder = [NSMutableArray  array];
	}
	
	if (param == nil || key == nil)
	{
		return;
	}
	
	(self.postParamsKeyValues)[key] = param;
	[self.postParamsOrder addObject:key];
}

- (BOOL)fetch:(NSError**)returnError;
{
	NSError             * error;
	NSMutableURLRequest * request;
	request = [[NSMutableURLRequest alloc] initWithURL:self.URL
										   cachePolicy:NSURLRequestReloadIgnoringCacheData 
									   timeoutInterval:60];
	request.HTTPMethod = self.HTTPMethod.length>0 ? self.HTTPMethod : @"GET";
	
	if (self.cookiesSource)
	{
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:self.cookiesSource.cookiesReturned forURL:self.cookiesSource.URL mainDocumentURL:nil];
		
		request.allHTTPHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:self.cookiesSource.cookiesReturned];
	}
	
	if (self.referrer)
	{
		[request addValue:self.referrer.URL.absoluteString forHTTPHeaderField:@"Referer"];

	}
	
	QRURLConnection *conn = [[QRURLConnection alloc] init];
	conn.request = request;
	conn.postParameters = self.postParamsKeyValues;
	conn.fieldOrdering = self.postParamsOrder;
	conn.useMultipartRatherThanURLEncoded = self.sendMultipartFormData;
	conn.addRadarSpoofingHeaders = YES;
	
	NSData *data = [conn fetchSyncWithError:&error];
	
	if (!data)
	{
		*returnError = error;
		return NO;
	}
	
	self.cookiesReturned = conn.cookiesReturned;
	self.returnedData = data;
	
	NSXMLDocument *newXMLDoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
	
	if (!newXMLDoc)
	{
		*returnError = error;
		return NO;
	}
	
	self.xmlDocument = newXMLDoc;
	return YES;
}


- (NSDictionary*)stringValuesForXPathsDictionary:(NSDictionary*)dict error:(NSError**)retError;
{
//	NSLog(@"Data %@", [[NSString alloc] initWithData:self.returnedData encoding:NSUTF8StringEncoding]);
	
	NSMutableDictionary *returnDict = [NSMutableDictionary dictionary];
	
	for (NSString *key in dict)
	{
		NSString *xpath = dict[key];
		
		NSError *error;
		NSXMLNode *element = [self.xmlDocument firstNodeForXPath:xpath error:&error];
		
		if (!element)
		{
			NSLog(@"Found no element %@", xpath);
			returnDict[key] = @"";
		}
		else
		{
			NSString *string = element.stringValue;
			
            if (string)
            {
                returnDict[key] = string;
            }
		}
	}
	
	return returnDict;
}


@end
