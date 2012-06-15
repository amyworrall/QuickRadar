//
//  RadarSubmission.m
//  QuickRadar
//
//  Created by Amy Worrall on 15/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RadarSubmission.h"
#import "NSXMLNode+Additions.h"
#import "SuperURLConnection.h"
#import <Security/Security.h>

@interface RadarSubmission ()
//{
//	void(^preparationCompleteHandler)(BOOL success);
//}

@end

@implementation RadarSubmission

@synthesize product, version, classification, reproducible, title, body, radarURL, radarNumber;


- (void)submitWithCompletionBlock:(void(^)(BOOL success))handler;
{
	void(^bail)() = ^(){
		dispatch_sync(dispatch_get_main_queue(), ^{ handler(NO); });
	};
	
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		NSHTTPURLResponse   * response;
		NSError             * error;
		NSMutableURLRequest * request;
		
		/*
		 * Fetch the login page
		 */
		
		request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://bugreport.apple.com/cgi-bin/WebObjects/RadarWeb.woa/wa/signIn"]
												cachePolicy:NSURLRequestReloadIgnoringCacheData 
											timeoutInterval:60];
		
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];  
		NSArray * all = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:response.URL];
//		NSLog(@"Cookying %@", response.URL);
		
		if (!response) { NSLog(@"No response"); bail(); return; };
		
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:all forURL:response.URL mainDocumentURL:nil];

//		for (NSHTTPCookie *cookie in all)
//			NSLog(@"Name: %@ : Value: %@, Expires: %@", cookie.name, cookie.value, cookie.expiresDate); 

		
		
		NSXMLDocument *doc = [[NSXMLDocument alloc] initWithData: data
																  options:NSXMLDocumentTidyXML 
																	error:&error];
//			NSLog(@"b4 form %@", error);
	
		if (!doc) { bail(); return; };
		
		NSXMLElement *form = [doc.rootElement firstElementForXPath:@"//form[@name='appleConnectForm']"];
//		NSLog(@"b4 form2");

		if (!form) { bail(); return; };
		
//		NSLog(@"Got form");
		
		NSString *loginAction = [form attributeForName:@"action"].stringValue;
		NSURL *loginURL = [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:loginAction];
		
//		NSLog(@"login URL = %@", loginURL);
//		return;
        NSString *serverName = @"bugreport.apple.com";
        char *passwordBytes = NULL;
        UInt32 passwordLength = 0;
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *username = [prefs objectForKey: @"username"];
		OSStatus keychainResult = SecKeychainFindInternetPassword(NULL,
                                                                  (UInt32)[serverName lengthOfBytesUsingEncoding: NSUTF8StringEncoding],
                                                                  [serverName cStringUsingEncoding: NSUTF8StringEncoding],
                                                                  0,
                                                                  NULL,
                                                                  (UInt32)[username lengthOfBytesUsingEncoding: NSUTF8StringEncoding],
                                                                  [username cStringUsingEncoding: NSUTF8StringEncoding],
                                                                  0,
                                                                  NULL,
                                                                  443,
                                                                  kSecProtocolTypeAny,
                                                                  kSecAuthenticationTypeAny,
                                                                  &passwordLength,
                                                                  (void **)&passwordBytes,
                                                                  NULL);
        if (keychainResult) { NSLog(@"Password not found");  bail(); return; };
		
		NSString *password = [NSString stringWithCString:passwordBytes length:passwordLength];
//        NSString *password2 = [NSString stringWithCString: passwordBytes encoding: NSUTF8StringEncoding];
						
        SecKeychainItemFreeContent(NULL, passwordBytes);
		NSDictionary *loginFormParams = [NSDictionary dictionaryWithObjectsAndKeys:
										 username, @"theAccountName",
										 password, @"theAccountPW",
										 @"4", @"1.Continue.x",
										 @"5", @"1.Continue.y",
										 @"", @"theAuxValue",
										 nil];
		
//		NSLog(@"Params %@", loginFormParams);
		
		NSMutableURLRequest *loginReq = [NSMutableURLRequest requestWithURL:loginURL];
		loginReq.allHTTPHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:all];
		loginReq.HTTPMethod = @"POST";
		[loginReq addValue:@"https://bugreport.apple.com/cgi-bin/WebObjects/RadarWeb.woa/wa/signIn" forHTTPHeaderField:@"Referer"];
//		NSLog(@"Header fields %@", loginReq.allHTTPHeaderFields);
		
		/*
		 * Fetching bounce page
		 */
		
		SuperURLConnection *conn = [[SuperURLConnection alloc] init];
		conn.request = loginReq;
		conn.postParameters = loginFormParams;
		
		data = [conn fetchSyncWithError:&error];
		
		NSLog(@"Fetch sync complete");
		
		if (!data)
		{
			NSLog(@"BBUC error %@", error);
		}
		
		NSXMLDocument *loginResponseDoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
		
//		NSLog(@"Root node %@", loginResponseDoc.rootElement);
		
		/* Now we should have the page that uses JS to bounce to the main WO app */
		
		form = [loginResponseDoc.rootElement firstElementForXPath:@"//form[@name='frmLinkMyOriginated']"];
		if (!form) { bail(); return; };
		
		NSString *bounceAction = [form attributeForName:@"action"].stringValue;
		NSURL *bounceURL = [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:bounceAction];
		
		/*
		 * Fetching the main Radar page (list of your open bugs etc)
		 */
		
		NSMutableURLRequest *jumpToMainReq = [NSMutableURLRequest requestWithURL:bounceURL];
		[jumpToMainReq addValue:[loginReq.URL absoluteString] forHTTPHeaderField:@"Referer"];
		jumpToMainReq.HTTPMethod = @"POST";
		
		
		conn = [[SuperURLConnection alloc] init];
		conn.request = jumpToMainReq;
		
		data = [conn fetchSyncWithError:&error];
		
		if (!data)
		{
			NSLog(@"BBUC error %@", error);
		}
		
		NSXMLDocument *jmResponseDoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];

//		NSLog(@"Root %@", jmResponseDoc.rootElement);
		
		/* Got the main bug reporter page */
		
		NSString *newProblemXpath = @"//td[@class='navlink']";
		NSXMLElement *td = [jmResponseDoc.rootElement firstElementForXPath:newProblemXpath];
		
//		NSArray *navlinks = [jmResponseDoc.rootElement nodesForXPath:newProblemXpath error:nil];
//		
//		for (NSXMLElement *element in navlinks)
//		{
//			NSLog(@"Element %@", element.stringValue);
//			NSXMLElement *a = [element firstElementForXPath:@"a"];	
//			NSLog(@"A %@", a.XMLString);
//			NSString *URL = [a attributeForName:@"href"].stringValue;
//			NSLog(@"URL: %@", URL);
//		}
		
//		NSLog(@"TD %@", td.stringValue);
		
		NSXMLElement *a = [td firstElementForXPath:@"a"];
		
//		NSLog(@"A %@", a.XMLString);
		
		NSString *URL = [a attributeForName:@"href"].stringValue;
		
		NSLog(@"URL: %@", URL);
		
		NSURL *newTicketURL =  [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:URL];;
		NSMutableURLRequest *newTicketReq = [NSMutableURLRequest requestWithURL:newTicketURL];
		[newTicketReq addValue:[jumpToMainReq.URL absoluteString] forHTTPHeaderField:@"Referer"];
		
		/* 
		 * Fetching the New Ticket page
		 */
		
		conn = [[SuperURLConnection alloc] init];
		conn.request = newTicketReq;
		
		data = [conn fetchSyncWithError:&error];

		NSXMLDocument *newBugPageDoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];

		
//		NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
		
		// Find the action for the bug report form
		
		form = [newBugPageDoc.rootElement firstElementForXPath:@"//form[@name='BugReportDetail']"];
		if (!form) { NSLog(@"Couldn't find submit form"); bail(); return; };

		NSString *bugReportURLString = [form attributeForName:@"action"].stringValue;
		
		// try seting name iPhoneFlag value Yes?
		
		NSXMLElement *element = [newBugPageDoc firstElementForXPath:@"//input[@id='probTitleNewProb']"];
		NSString *newProbName = [element attributeForName:@"name"].stringValue;
				
		element = [newBugPageDoc firstElementForXPath:@"//input[@id='initialPopulateFlag']"];
		NSString *initialPopulateFlagName = [element attributeForName:@"name"].stringValue;
		
		// version number is name configSummary
		// classification is name classlist
		// product is name prodList. EG: 'Accessibility' is 437784
		
		element = [newBugPageDoc firstElementForXPath:@"//select[@id='reproducibleNewProb']"];
		NSString *isItReproducibleName = [element attributeForName:@"name"].stringValue;
		NSString *reproducibleNumber = nil;
		for (NSXMLElement *child in element.children)
		{
			if ([child.stringValue isEqualToString:[self.reproducible stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]])
			{
				reproducibleNumber = [child attributeForName:@"value"].stringValue;
			}
		}


		// refreshCount name/value
		element = [newBugPageDoc firstElementForXPath:@"//input[@id='refreshCount']"];
		NSString *rcName = [element attributeForName:@"name"].stringValue;
		NSString *rcValue = [element attributeForName:@"value"].stringValue;

		// configEmptyFlag -- the value should be 'flag'
		element = [newBugPageDoc firstElementForXPath:@"//input[@id='configEmptyFlag']"];
		NSString *configEmptyFlagName = [element attributeForName:@"name"].stringValue;
		
		// configInformation
		element = [newBugPageDoc firstElementForXPath:@"//input[@id='configInformation']"];
		NSString *configInformationName = [element attributeForName:@"name"].stringValue;
		
		// config ID
		element = [newBugPageDoc firstElementForXPath:@"//input[@id='confgID']"];
		NSString *configIDName = [element attributeForName:@"name"].stringValue;
		
		// select a config
		// This is hard coded 'cos it always seems to be the same in testing, and the item has no ID to do an unambiguous xpath on
		NSString *appendNewConfigName = @"61.103.49";
		
		// config info
		element = [newBugPageDoc firstElementForXPath:@"//textarea[@id='ConfigInfo']"];
		NSString *configInfoTextareaName = [element attributeForName:@"name"].stringValue;
		
		// Find out the product list number
		NSString *productListNumber = nil;
		element = [newBugPageDoc firstElementForXPath:@"//select[@id='prodList']"];
		for (NSXMLElement *child in element.children)
		{
			if ([child.stringValue isEqualToString:self.product])
			{
				productListNumber = [child attributeForName:@"value"].stringValue;
			}
		}
		
		NSString *classificationNumber = nil;
		element = [newBugPageDoc firstElementForXPath:@"//select[@id='classList']"];
		for (NSXMLElement *child in element.children)
		{
			if ([[child.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:[self.classification stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]])
			{
				classificationNumber = [child attributeForName:@"value"].stringValue;
			}
		}


		/* 
		 * Assembling the submission
		 */
		
		NSMutableDictionary *bugSubmissionForm = [NSMutableDictionary dictionary];
		NSMutableDictionary *fileParams = [NSMutableDictionary dictionary];
		
		/* refreshCount */
		[bugSubmissionForm setObject:rcValue forKey:rcName];
		
		/* formatAddFlag */
		[bugSubmissionForm setObject:@"No" forKey:@"formatAddFlag"];
		
		/* version/build number */
		[bugSubmissionForm setObject:self.version forKey:@"configSummary"];
		
		/* configEmptyFlag */
		[bugSubmissionForm setObject:@"flag" forKey:configEmptyFlagName];
		
		/* iphone flag */
		[bugSubmissionForm setObject:@"No" forKey:@"iPhoneFlag"];
		
		/* bug title */
		[bugSubmissionForm setObject:self.title forKey:newProbName];
		
		/* product */
		[bugSubmissionForm setObject:productListNumber forKey:@"prodList"];
		
		/* classification */
		[bugSubmissionForm setObject:classificationNumber forKey:@"classList"];
		
		/* reproducible */
		[bugSubmissionForm setObject:reproducibleNumber forKey:isItReproducibleName];
		
		/* description */
		[bugSubmissionForm setObject:self.body forKey:@"probDesc"];
		
		/* config information */
		[bugSubmissionForm setObject:@"" forKey:configInformationName];
		
		/* config ID (file upload) */
		[fileParams setObject:[NSData data] forKey:configIDName];
		
		/* select a config */
		[bugSubmissionForm setObject:@"WONoSelectionString" forKey:appendNewConfigName];
		
		/* select a config */
		[bugSubmissionForm setObject:@"" forKey:configInfoTextareaName];
		
		/* initial populate flag */
		[bugSubmissionForm setObject:@"No" forKey:initialPopulateFlagName]; // this probably isn't used, apart from by JavaScript
		
		/* file */
		[fileParams setObject:[NSData data] forKey:@"__DEFAULT__FILE__1__"];
		
		/* Save */
		[bugSubmissionForm setObject:@"25" forKey:@"Save.x"];
		[bugSubmissionForm setObject:@"16" forKey:@"Save.y"];

		NSArray *ordering = [NSArray arrayWithObjects:
							 rcName,
							 @"formatAddFlag",
							 configInformationName,
							 configEmptyFlagName,
							 @"iPhoneFlag",
							 newProbName,
							 @"prodList",
							 @"configSummary",
							 @"classList",
							 isItReproducibleName,
							 @"probDesc",
							 initialPopulateFlagName,
							 configIDName,
							 appendNewConfigName,
							 configInformationName,
							 @"__DEFAULT__FILE__1__",
							 @"Save.x",
							 @"Save.y",
							 nil];
		
		NSLog(@"%@", bugSubmissionForm);
		
		
		/*
		 * Actually submitting the ticket
		 */
		
		SuperURLConnection *submitBugConnection = [[SuperURLConnection alloc] init];
		NSMutableURLRequest *submitBugURLRequest = [NSMutableURLRequest requestWithURL: [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:bugReportURLString] ];
		submitBugURLRequest.HTTPMethod = @"POST";
		submitBugURLRequest.allHTTPHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:conn.cookiesReturned];
		[submitBugURLRequest addValue:[newTicketReq.URL absoluteString] forHTTPHeaderField:@"Referer"];
		
		submitBugConnection.request = submitBugURLRequest;
		submitBugConnection.postParameters = bugSubmissionForm;
		submitBugConnection.fileParameters = fileParams;
		submitBugConnection.fieldOrdering = ordering;
		submitBugConnection.useMultipartRatherThanURLEncoded = YES;
		
		
		data = [submitBugConnection fetchSyncWithError:&error];
		
//		NSLog(@"Final page %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
		
		NSXMLDocument *successOrFailPage = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
		
		

		
		NSArray *aTags = [successOrFailPage nodesForXPath:@"//a" error:&error];
		NSArray *fontTags = [successOrFailPage nodesForXPath:@"//font" error:&error];

//		NSLog(@"A: %@", aTags);
//		NSLog(@"Font: %@", fontTags);
		
		if (aTags.count < 6 || fontTags.count < 6)
		{
			bail(); return;
		}
		
		self.radarNumber = ((NSXMLElement*)[fontTags objectAtIndex:5]).stringValue;
		self.radarURL = [@"https://bugreport.apple.com" stringByAppendingPathComponent: [((NSXMLElement*)[aTags objectAtIndex:5]) attributeForName:@"href"].stringValue ];
		
		
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			handler(YES);
		});
	});
}





@end
