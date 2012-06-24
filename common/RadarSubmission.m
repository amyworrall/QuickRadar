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
#import "PasswordStoring.h"
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
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = [self submit];
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			handler(error==nil);
		});
	});
}

- (NSError*)submit {
    NSError *error = nil;
    
    //login and get main url or error out
    NSMutableURLRequest *mainRequest = [self doLoginAndProcceedToMainWithError:&error];
    if(mainRequest) {
        error = nil;
        NSURLRequest *newTicketRequest = [self loadMainPageAndNewTicketPage:mainRequest withError:&error];
        if(newTicketRequest) {
            error = nil;
            NSXMLDocument *finalPage = [self doSubmitWithRequest:newTicketRequest withError:&error];
            
            if(finalPage) {
                error = nil;
                
                //interpret success page
                NSArray *aTags = [finalPage nodesForXPath:@"//a" error:nil];
                NSArray *fontTags = [finalPage nodesForXPath:@"//font" error:nil];
                self.radarNumber = ((NSXMLElement*)[fontTags objectAtIndex:5]).stringValue;
                self.radarURL = [@"https://bugreport.apple.com" stringByAppendingPathComponent: [((NSXMLElement*)[aTags objectAtIndex:5]) attributeForName:@"href"].stringValue ];
            }
        }
    }
    
    if(error)
        NSLog(@"%@", error);
    return error;
}

#pragma mark -

- (NSMutableURLRequest*)doLoginAndProcceedToMainWithError:(NSError**)pError {
    *pError = nil;
    
    //setup login request
    NSURL *urlForLogin = [NSURL URLWithString:@"https://bugreport.apple.com/cgi-bin/WebObjects/RadarWeb.woa/wa/signIn"];
    NSMutableURLRequest *loginRequest = [[NSMutableURLRequest alloc]initWithURL:urlForLogin
                                                                     cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                                 timeoutInterval:60];
    
    //force UserAgent
    [loginRequest addValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/534.55.3 (KHTML, like Gecko) Version/5.1.5 Safari/534.55.3"
        forHTTPHeaderField:@"User-Agent"];

    //do and read
    NSHTTPURLResponse *loginResponse = nil;
    NSData *loginData = [NSURLConnection sendSynchronousRequest:loginRequest
                                              returningResponse:&loginResponse
                                                          error:pError];

    //check response
    if (![loginResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        if(!*pError)
            *pError = [NSError errorWithDomain:@"QR" code:1 userInfo:@{NSLocalizedDescriptionKey: @"No response. cant get login page"}];
        return nil;
    }
    
    //apply cookies
    NSArray *loginCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[loginResponse allHeaderFields]
                                                                   forURL:loginResponse.URL];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:loginCookies
                                                       forURL:loginResponse.URL mainDocumentURL:nil];
    
    //check login data
    if (!loginData.length)
    {
        *pError = [NSError errorWithDomain:@"QR" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Login page had a response but no data"}];
        return nil;
    }
    
    //parse login page data as xml
    NSXMLDocument *loginDoc = [[NSXMLDocument alloc] initWithData: loginData options:NSXMLDocumentTidyHTML error:pError];
    if (!loginDoc) {
        if(!*pError)
            *pError = [NSError errorWithDomain:@"QR" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Cant parse html data of login page"}];
        return nil;
    };
    
    //get login form
    NSXMLElement *loginForm = [loginDoc.rootElement firstElementForXPath:@"//form[@name='appleConnectForm']"];
    if (!loginForm) {
        *pError = [NSError errorWithDomain:@"QR" code:4 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't find appleConnectForm form"}];
        return nil;
    };
    
    //get login action
    NSString *loginAction = [loginForm attributeForName:@"action"].stringValue;
    if (!loginAction.length) {
        *pError = [NSError errorWithDomain:@"QR" code:5 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't find loginAction in appleConnectForm form"}];
        return nil;
    };
   
    //load credentials
    PasswordStoring *store = [[PasswordStoring alloc] init];
    [store load];
    if(!store.username.length || !store.password.length)
    {
        *pError = [NSError errorWithDomain:@"QR" code:6 userInfo:[NSDictionary dictionaryWithObject:@"No User or password" forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
        
    //prepare login dict
    NSURL *loginURL = [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:loginAction];
    NSDictionary *loginFormParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                     store.username, @"theAccountName",
                                     store.password, @"theAccountPW",
                                     @"4", @"1.Continue.x",
                                     @"5", @"1.Continue.y",
                                     @"", @"theAuxValue",
                                     nil];

    //prepare login request
    NSMutableURLRequest *loginReq = [NSMutableURLRequest requestWithURL:loginURL];
    loginReq.allHTTPHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:loginCookies];
    loginReq.HTTPMethod = @"POST";
    [loginReq addValue:@"https://bugreport.apple.com/cgi-bin/WebObjects/RadarWeb.woa/wa/signIn" forHTTPHeaderField:@"Referer"];
    
    //fetch bounce page
    SuperURLConnection *conn = [[SuperURLConnection alloc] init];
    conn.request = loginReq;
    conn.postParameters = loginFormParams;
    NSData *signInData = [conn fetchSyncWithError:pError];
        
    //verify data
    if (!signInData.length)
    {
        if(!*pError)
            *pError = [NSError errorWithDomain:@"QR" code:7 userInfo:@{NSLocalizedDescriptionKey: @"Sign In resulted in 0 data"}];
        return nil;
    }
    
    //get xml
    NSXMLDocument *loginResponseDoc = [[NSXMLDocument alloc] initWithData:signInData options:NSXMLDocumentTidyHTML error:pError];
    if (!loginResponseDoc) {
        if(!*pError)
            *pError = [NSError errorWithDomain:@"QR" code:8 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't parse data to xml doc after sign in"}];
        return nil;
    };
    
    //read form
    NSXMLElement *bounceBackForm = [loginResponseDoc.rootElement firstElementForXPath:@"//form[@name='frmLinkMyOriginated']"];
    if (!bounceBackForm) {
       *pError = [NSError errorWithDomain:@"QR" code:9 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't find frmLinkMyOriginated form"}];
        return nil;
    };
    
    //get action
    NSString *bounceAction = [bounceBackForm attributeForName:@"action"].stringValue;
    if(!bounceAction.length) {
        *pError = [NSError errorWithDomain:@"QR" code:9 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't find bounce action in frmLinkMyOriginated form"}];
        return nil;
    }
        
    //setup bounce to take us back and return it
    NSURL *bounceURL = [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:bounceAction];
    NSMutableURLRequest *jumpToMainReq = [NSMutableURLRequest requestWithURL:bounceURL];
    [jumpToMainReq addValue:[loginReq.URL absoluteString] forHTTPHeaderField:@"Referer"];
    jumpToMainReq.HTTPMethod = @"POST";
    return jumpToMainReq;
}

- (NSURLRequest*)loadMainPageAndNewTicketPage:(NSURLRequest*)jumpToMainReq withError:(NSError**)pError {
    *pError = nil;
    
    //fetch main
    SuperURLConnection *mainConn = [[SuperURLConnection alloc] init];
    mainConn.request = jumpToMainReq;
    NSData *mainPageData = [mainConn fetchSyncWithError:pError];
    
    //verify data
    if (!mainPageData.length) {
        if(!*pError)
            *pError = [NSError errorWithDomain:@"QR" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Fetching main page resulted in 0 data"}];
        return nil;
    }

    //parse to xml
    NSXMLDocument *jmResponseDoc = [[NSXMLDocument alloc] initWithData:mainPageData options:NSXMLDocumentTidyHTML error:pError];
    if (!jmResponseDoc)
    {
        *pError = [NSError errorWithDomain:@"QR" code:101 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't parse main page data to xml"}];
        return nil;
    }
    
    //get the main bug reporter page href
    NSString *newProblemXpath = @"//td[@class='navlink']";
    NSXMLElement *td = [jmResponseDoc.rootElement firstElementForXPath:newProblemXpath];
    NSXMLElement *a = [td firstElementForXPath:@"a"];
    NSString *URL = [a attributeForName:@"href"].stringValue;
    
    //failed to get url of reporter
    if(!URL.length) {
        *pError = [NSError errorWithDomain:@"QR" code:101 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't find url for a new ticket"}];
        return nil;
    }
    
    //new ticket urlrequest and return it
    NSURL *newTicketURL =  [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:URL];;
    NSMutableURLRequest *newTicketReq = [NSMutableURLRequest requestWithURL:newTicketURL];
    [newTicketReq addValue:[jumpToMainReq.URL absoluteString] forHTTPHeaderField:@"Referer"];
    return newTicketReq;
}

- (NSXMLDocument*)doSubmitWithRequest:(NSURLRequest*)newTicketRequest withError:(NSError**)pError {
    //fetch new ticket page
    SuperURLConnection *conn = [[SuperURLConnection alloc] init];
    conn.request = newTicketRequest;
    NSData *newTicketRequestData = [conn fetchSyncWithError:pError];
    
    //verify
    if (!newTicketRequestData.length)
    {
        if(!*pError)
            *pError = [NSError errorWithDomain:@"QR" code:102 userInfo:@{NSLocalizedDescriptionKey: @"No Data for the new ticket page"}];
        return nil;
    }
    
    //parse as xml
    NSXMLDocument *newBugPageDoc = [[NSXMLDocument alloc] initWithData:newTicketRequestData
                                                               options:NSXMLDocumentTidyHTML
                                                                 error:pError];
    if(!newBugPageDoc) {
        if(!*pError)
            *pError = [NSError errorWithDomain:@"QR" code:103 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't make data of new ticket page into xml"}];
        return nil;
    }
    
    // Find the action for the bug report form    
    NSXMLElement* form = [newBugPageDoc.rootElement firstElementForXPath:@"//form[@name='BugReportDetail']"];
    if (!form) {
        *pError = [NSError errorWithDomain:@"QR" code:104 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't find BugReportDetail form on ticket page"}];
        return nil;
    };
    
    //get url
    NSString *bugReportURLString = [form attributeForName:@"action"].stringValue;
    if (!bugReportURLString.length) {
        *pError = [NSError errorWithDomain:@"QR" code:105 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't find action in bugReport form"}];
        return nil;
    };
    
    /*
    //setup all sending
     */
    NSDictionary *bugSubmissionForm = nil;
    NSDictionary *fileParams = nil;
    NSArray *ordering = nil;
    NSError *error = [self prepareSubmissionFromDocument:newBugPageDoc
                                    getBugSubmissionForm:&bugSubmissionForm
                                           getFileParams:&fileParams
                                             getOrdering:&ordering];
    if(error)
    {
        *pError = error;
        return nil;
    }
    
    
    /*
     * Actually submitting the ticket
     */    
    SuperURLConnection *submitBugConnection = [[SuperURLConnection alloc] init];
    NSMutableURLRequest *submitBugURLRequest = [NSMutableURLRequest requestWithURL: [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:bugReportURLString] ];
    submitBugURLRequest.HTTPMethod = @"POST";
    submitBugURLRequest.allHTTPHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:conn.cookiesReturned];
    [submitBugURLRequest addValue:[newTicketRequest.URL absoluteString]
               forHTTPHeaderField:@"Referer"];
    
    submitBugConnection.request = submitBugURLRequest;
    submitBugConnection.postParameters = bugSubmissionForm;
    submitBugConnection.fileParameters = fileParams;
    submitBugConnection.fieldOrdering = ordering;
    submitBugConnection.useMultipartRatherThanURLEncoded = YES;
    
    NSData *bugSubmittedData = [submitBugConnection fetchSyncWithError:pError];

    //verify
    if (!bugSubmittedData.length)
    {
        if(!*pError)
            *pError = [NSError errorWithDomain:@"QR" code:107 userInfo:@{NSLocalizedDescriptionKey: @"No data from final page"}];
        return nil;
    }
    
    //parse to xml
    NSXMLDocument *successOrFailPage = [[NSXMLDocument alloc] initWithData:bugSubmittedData
                                                                   options:NSXMLDocumentTidyHTML error:pError];
    if(!successOrFailPage) {
        if(!*pError)
            *pError = [NSError errorWithDomain:@"QR" code:108 userInfo:@{NSLocalizedDescriptionKey: @"No parse XML from final page data"}];
        return nil;
    }
    
    //get count of a tags and font tags to verify
    NSArray *aTags = [successOrFailPage nodesForXPath:@"//a" error:nil];
    NSArray *fontTags = [successOrFailPage nodesForXPath:@"//font" error:nil];
    if (aTags.count < 6 || fontTags.count < 6)
    {
        if(!*pError)
            *pError = [NSError errorWithDomain:@"QR" code:109 userInfo:@{NSLocalizedDescriptionKey: @"Verification of final page failed. Mark submission as failed"}];
        return nil;
    }
    
    //YAY
    return successOrFailPage;
}

- (NSError*)prepareSubmissionFromDocument:(NSXMLDocument*)newBugPageDoc getBugSubmissionForm:(NSDictionary**)pBugSubmissionForm getFileParams:(NSDictionary**)pFileParams getOrdering:(NSArray**)pOrdering
{
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
    
    /*ordering of params */
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
        
    *pBugSubmissionForm = bugSubmissionForm;
    *pFileParams = fileParams;
    *pOrdering = ordering;
    
    return nil;
}
@end
