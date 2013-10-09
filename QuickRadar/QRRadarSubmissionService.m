//
//  QRRadarSubmissionService.m
//  QuickRadar
//
//  Created by Amy Worrall on 26/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRRadarSubmissionService.h"
#import "QRWebScraper.h"
#import "NSError+Additions.h"
#import "OrderedDictionary.h"


@interface QRRadarSubmissionService ()

@property (atomic, assign) CGFloat progressValue;
@property (atomic, assign) SubmissionStatus submissionStatusValue;
@property (atomic, assign) NSString *submissionStatusText;

@end


@implementation QRRadarSubmissionService


@synthesize progressValue = _progressValue;
@synthesize submissionStatusValue = _submissionStatusValue;


+ (void)load
{
	[QRSubmissionService registerService:self];
}

+ (NSString *)identifier
{
	return QRRadarSubmissionServiceIdentifier;
}

+ (NSString *)name
{
	return @"Apple Radar";
}

+ (BOOL)isAvailable
{
	return YES;
}

+ (BOOL)requireCheckBox;
{
	return NO;
}

+ (BOOL)supportedOnMac;
{
	return YES;
}

+ (BOOL)supportedOniOS;
{
	return NO;
}

+ (NSString*)macSettingsViewControllerClassName;
{
	return @"QRRadarSubmissionServicePreferencesViewController";
}

+ (NSString*)iosSettingsViewControllerClassName;
{
	return nil;
}

+ (id)settingsIconPlatformAppropriateImage;
{
	if (NSClassFromString(@"NSImage"))
	{
		return [NSImage imageNamed:@"AppleLogoTemplate"];
	}
	return nil;
}

- (CGFloat)progress
{
	return self.progressValue;
}

- (SubmissionStatus)submissionStatus
{
	return self.submissionStatusValue;
}

- (NSString *)statusText
{
    return self.submissionStatusText;
}


#define NUM_PAGES 5

- (void)submitAsyncWithProgressBlock:(void (^)())progressBlock completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		
		
		self.submissionStatusValue = submissionStatusInProgress;
		
		NSError *error = nil;
		
		
		/**********************
		 * Page 1: login page *
		 **********************/
		
        self.submissionStatusText = @"Fetching RadarWeb signin page";
		QRWebScraper *loginPage = [[QRWebScraper alloc] init];
		loginPage.URL = [NSURL URLWithString:@"https://idmsa.apple.com/IDMSWebAuth/classicLogin.html?appIdKey=77e2a60d4bdfa6b7311c854a56505800be3c24e3a27a670098ff61b69fc5214b&sslEnabled=true&rv=3"];
		
		if (![loginPage fetch:&error])
		{
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				completionBlock(NO, error);
			});
			return;
		}
		else
		{
			self.progressValue = 1 * (1.0/NUM_PAGES);
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				progressBlock();
			});
		}
		
		// ------- Parsing --------
		
		NSDictionary *loginPageXpaths = @{@"action": @"//form[@name='form2']/@action"};
		
		NSDictionary *loginPageValues = [loginPage stringValuesForXPathsDictionary:loginPageXpaths error:&error];
		
		if (!loginPageValues)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		
		
		/**************************
		 * Page 2: Submitting the login *
		 **************************/
		
        self.submissionStatusText = @"Signing into RadarWeb";
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		NSString *username = [prefs objectForKey: @"username"];
		NSString *password = [self radarPassword];
		
		NSURL *bouncePageURL = [NSURL URLWithString:@"https://idmsa.apple.com/IDMSWebAuth/authenticate.html"];
		
		
		QRWebScraper *bouncePage = [[QRWebScraper alloc] init];
		bouncePage.URL = bouncePageURL;
		bouncePage.cookiesSource = loginPage;
		bouncePage.referrer = loginPage;
		bouncePage.HTTPMethod = @"POST";
		
		[bouncePage addPostParameter:username forKey:@"appleId"];
		[bouncePage addPostParameter:password forKey:@"accountPassword"];
        [bouncePage addPostParameter:@"{\"U\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1\",\"L\":\"en-us\",\"Z\":\"GMT+01:00\",\"V\":\"1.1\",\"F\":\"TF1;016;;;;;;;;;;;;;;;;;;;;;;Mozilla;Netscape;5.0%20%28Macintosh%3B%20Intel%20Mac%20OS%20X%2010_8_4%29%20AppleWebKit/536.30.1%20%28KHTML%2C%20like%20Gecko%29%20Version/6.0.5%20Safari/536.30.1;20030107;undefined;true;;true;MacIntel;undefined;Mozilla/5.0%20%28Macintosh%3B%20Intel%20Mac%20OS%20X%2010_8_4%29%20AppleWebKit/536.30.1%20%28KHTML%2C%20like%20Gecko%29%20Version/6.0.5%20Safari/536.30.1;en-us;iso-8859-1;idmsa.apple.com;undefined;undefined;undefined;undefined;true;true;1378980528007;0;7%20June%202005%2021%3A33%3A44%20BST;2560;1440;undefined;undefined;undefined;;undefined;undefined;2;0;-60;12%20September%202013%2011%3A08%3A48%20BST;24;2560;1330;0;22;;;;;;Shockwave%20Flash%7CShockwave%20Flash%2011.8%20r800;;;;QuickTime%20Plug-in%207.7.1%7CThe%20QuickTime%20Plugin%20allows%20you%20to%20view%20a%20wide%20variety%20of%20multimedia%20content%20in%20web%20pages.%20For%20more%20information%2C%20visit%20the%20%3CA%20HREF%3Dhttp%3A//www.apple.com/quicktime%3EQuickTime%3C/A%3E%20Web%20site.;;;;;;;;;18;;;;;;;\"}" forKey:@"fdcBrowserData"];

		
		if (![bouncePage fetch:&error])
		{
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		else
		{
			self.progressValue = 2 * (1.0/NUM_PAGES);
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				progressBlock();
			});
		}
        
        
       
		// ------- Parsing --------
		
		NSDictionary *bouncePageXpaths = @{  @"alertIcon": @"//img[@id='alert_icon']/@src"};
		
		NSDictionary *bouncePageValues = [bouncePage stringValuesForXPathsDictionary:bouncePageXpaths error:&error];
		
		if (!bouncePageValues)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		
		if ([bouncePageValues[@"alertIcon"] length] > 0)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				NSError *authError = [NSError authenticationErrorWithServiceIdentifier:self.class.identifier underlyingError:error];
				
				self.submissionStatusValue = submissionStatusFailed;
				self.progressValue = 0; // set this to 0 because it would be safe to retry the whole operation.
				completionBlock(NO, authError);
 			});
			return;
		}
        
        
		/***************************
		 * Page 3: Radar main page *
		 ***************************/
		
		
        self.submissionStatusText = @"Fetching RadarWeb main page";
		NSURL *mainPageURL = [NSURL URLWithString:@"https://bugreport.apple.com"];
		
		QRWebScraper *mainPage = [[QRWebScraper alloc] init];
		mainPage.URL = mainPageURL;
		mainPage.cookiesSource = bouncePage;
		mainPage.referrer = bouncePage;
		mainPage.HTTPMethod = @"POST";
		
		if (![mainPage fetch:&error])
		{
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		else
		{
			self.progressValue = 3 * (1.0/NUM_PAGES);
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				progressBlock();
			});
		}
        
//        NSLog(@"Main page: %@", [[NSString alloc] initWithData:mainPage.returnedData encoding:NSUTF8StringEncoding]);
		
		// ------- Parsing --------
		
		// Let's get the token.
        
        NSDictionary *mainPageXpaths = @{  @"csrfToken": @"//input[@id='csrftokenPage']/@value"};
		
		NSDictionary *mainPageValues = [mainPage stringValuesForXPathsDictionary:mainPageXpaths error:&error];
		
		if (!mainPageValues)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		
		NSString *csrfToken = mainPageValues[@"csrfToken"];
        
        /***************************
		 * A bunch of pages in the hope one of them will work *
		 ***************************/

        NSTimeInterval ti1 = [[NSDate date] timeIntervalSince1970];
        long milliseconds1 = ti1*1000;
        
        self.submissionStatusText = @"Fetching product list";
        NSURL *pageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://bugreport.apple.com/developer/problem/getProductFullList?_=%li", milliseconds1]];
		
        QRWebScraper *aPage = [[QRWebScraper alloc] init];
		aPage.URL = pageURL;
		aPage.cookiesSource = mainPage;
		aPage.referrer = mainPage;
		aPage.HTTPMethod = @"GET";
        aPage.customHeaders = @{@"csrftokencheck" : csrfToken, @"X-Requested-With" : @"XMLHttpRequest", @"Accept" : @"application/json, text/javascript, */*; q=0.01"};
		
		if (![aPage fetch:&error])
		{
			dispatch_sync(dispatch_get_main_queue(), ^{
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		else
		{
			self.progressValue = 4 * (1.0/NUM_PAGES);
			dispatch_sync(dispatch_get_main_queue(), ^{
				progressBlock();
			});
		}
        

        
        ti1 = [[NSDate date] timeIntervalSince1970];
         milliseconds1 = ti1*1000;
        
        self.submissionStatusText = @"Getting counts";
        pageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://bugreport.apple.com/developer/problem/getAllCounts?_=%li", milliseconds1]];
		
        aPage = [[QRWebScraper alloc] init];
		aPage.URL = pageURL;
		aPage.cookiesSource = mainPage;
		aPage.referrer = mainPage;
		aPage.HTTPMethod = @"GET";
        aPage.customHeaders = @{@"csrftokencheck" : csrfToken, @"X-Requested-With" : @"XMLHttpRequest", @"Accept" : @"application/json, text/javascript, */*; q=0.01"};
		
		if (![aPage fetch:&error])
		{
			dispatch_sync(dispatch_get_main_queue(), ^{
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		else
		{
			self.progressValue = 4 * (1.0/NUM_PAGES);
			dispatch_sync(dispatch_get_main_queue(), ^{
				progressBlock();
			});
		}
        
        
        
        ti1 = [[NSDate date] timeIntervalSince1970];
        milliseconds1 = ti1*1000;
        
        self.submissionStatusText = @"Requesting section";
        pageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://bugreport.apple.com/developer/problem/getSectionProblems"]];
		
        aPage = [[QRWebScraper alloc] init];
		aPage.URL = pageURL;
		aPage.cookiesSource = mainPage;
		aPage.referrer = mainPage;
		aPage.HTTPMethod = @"POST";
        aPage.customBody = [@"{\"reportID\":\"Attention\",\"orderBy\":\"DateOriginated,Descending\",\"rowStartString\":\"1\"}" dataUsingEncoding:NSUTF8StringEncoding];
        aPage.customHeaders = @{@"csrftokencheck" : csrfToken, @"X-Requested-With" : @"XMLHttpRequest", @"Accept" : @"application/json, text/javascript, */*; q=0.01"};
		
		if (![aPage fetch:&error])
		{
			dispatch_sync(dispatch_get_main_queue(), ^{
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		else
		{
			self.progressValue = 4 * (1.0/NUM_PAGES);
			dispatch_sync(dispatch_get_main_queue(), ^{
				progressBlock();
			});
		}
        
        
        ti1 = [[NSDate date] timeIntervalSince1970];
        milliseconds1 = ti1*1000;
        
        self.submissionStatusText = @"Requesting drafts";
        pageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://bugreport.apple.com/developer/problem/fetchDraftInfo?_=%li", milliseconds1]];
		
        aPage = [[QRWebScraper alloc] init];
		aPage.URL = pageURL;
		aPage.cookiesSource = mainPage;
		aPage.referrer = mainPage;
		aPage.HTTPMethod = @"GET";
        aPage.customHeaders = @{@"csrftokencheck" : csrfToken, @"X-Requested-With" : @"XMLHttpRequest", @"Accept" : @"application/json, text/javascript, */*; q=0.01"};
		
		if (![aPage fetch:&error])
		{
		}
		else
		{
			self.progressValue = 4 * (1.0/NUM_PAGES);
			dispatch_sync(dispatch_get_main_queue(), ^{
				progressBlock();
			});
		}
        
        /***************************
		 * Keepalive *
		 ***************************/
        
        NSTimeInterval ti = [[NSDate date] timeIntervalSince1970];
        long milliseconds = ti*1000;
        
        self.submissionStatusText = @"Sending Keepalive Request";
		NSURL *keepaliveURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://bugreport.apple.com/developer/problem/keepAliveSession?_=%li", milliseconds]];
		
		QRWebScraper *keepalivePage = [[QRWebScraper alloc] init];
		keepalivePage.URL = keepaliveURL;
		keepalivePage.cookiesSource = mainPage;
		keepalivePage.referrer = mainPage;
		keepalivePage.HTTPMethod = @"GET";
        keepalivePage.customHeaders = @{@"csrftokencheck" : csrfToken};
		
		if (![keepalivePage fetch:&error])
		{
			dispatch_sync(dispatch_get_main_queue(), ^{
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		else
		{
			self.progressValue = 4 * (1.0/NUM_PAGES);
			dispatch_sync(dispatch_get_main_queue(), ^{
				progressBlock();
			});
		}

        
        
        /***************************
		 * Preprocess radar body *
		 ***************************/
        
        NSString *radarBody = self.radar.body;
        
        radarBody = [radarBody stringByReplacingOccurrencesOfString:@"\n" withString:@"\r\n"];
        
        
        NSString *radarCompleteText = [radarBody copy];
        
        
        /***************************
		 * Create our ticket *
		 ***************************/
		

        OrderedDictionary *ticket = [OrderedDictionary new];
        
        ticket[@"problemTitle"] = self.radar.title;
        ticket[@"configIDPop"] = @"";
        ticket[@"configTitlePop"] = @"";
        ticket[@"configDescriptionPop"] = @"";
        ticket[@"configurationText"] = @"";
        ticket[@"hiddenFileSizeNew"] = @"";
        ticket[@"notes"] = @"";
        ticket[@"workAroundText"] = @"";
        ticket[@"descriptionText"] = radarCompleteText;
        ticket[@"classificationCode"] = [NSString stringWithFormat:@"%ld", (long)self.radar.classificationCode];
        ticket[@"reproducibilityCode"] = [NSString stringWithFormat:@"%ld", (long)self.radar.reproducibleCode];
        
        NSDictionary *component = @{@"ID" : [NSString stringWithFormat:@"%ld", (long)self.radar.productCode],
                                    @"compName" : self.radar.product};
        ticket[@"component"] = component;
        
        ticket[@"draftID"] = @"";
        ticket[@"draftFlag"] = @"0";
        ticket[@"versionBuild"] = @"";
        ticket[@"desctextvalidate"] = radarBody;
        ticket[@"stepstoreprvalidate"] = @"";
        ticket[@"experesultsvalidate"] = @"";
        ticket[@"actresultsvalidate"] = @"";
        ticket[@"addnotesvalidate"] = @"";
        ticket[@"csrftokencheck"] = csrfToken;
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:ticket options:0 error:&error];
		NSString *jsonText = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
 		
		/*******************************
		 * Page 5: Bug Submission Page *
		 *******************************/
		
        self.submissionStatusText = @"Submitting bug to RadarWeb";
		NSURL *bugSubmissionURL =  [NSURL URLWithString:@"https://bugreport.apple.com/developer/problem/createNewDevUIProblem"];
		
		QRWebScraper *bugSubmissionPage = [[QRWebScraper alloc] init];
		bugSubmissionPage.URL = bugSubmissionURL;
		bugSubmissionPage.referrer = @"https://bugreport.apple.com/problem/viewproblem";
		bugSubmissionPage.HTTPMethod = @"POST";
		bugSubmissionPage.sendMultipartFormData = YES;
        bugSubmissionPage.shouldParseXML = NO;
		
		// Sets up all the fields necessary for submission.
		[bugSubmissionPage addPostParameter:jsonText forKey:@"hJsonScreenVal"];
		[bugSubmissionPage addPostParameter:jsonText forKey:@"hJsonScreenVal"];
		
		
		if (![bugSubmissionPage fetch:&error])
		{
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		else
		{
			self.progressValue = 5 * (1.0/NUM_PAGES);
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				progressBlock();
			});
		}
		
		// ------- Parsing --------
		
		NSData *resultData = bugSubmissionPage.returnedData;
        NSString *radarNumberString = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
		
		NSInteger radarNumberResult = [radarNumberString integerValue];
		
		// TODO: work out what error pages RadarWeb can display, and in this if statement make a new NSError filling in the text as appropriate.
		if (radarNumberResult <= 0)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, nil);
			});
			return;
		}
		
		/************
		 * Success! *
		 ************/
		
		
		self.radar.radarNumber = radarNumberResult;

		self.progressValue = 1.0;
		self.submissionStatusValue = submissionStatusCompleted;

		dispatch_sync(dispatch_get_main_queue(), ^{ 
			progressBlock();
			completionBlock(YES, nil);
		});
		
	});
}


- (NSString *)radarPassword
{
	NSString *serverName = @"bugreport.apple.com";
	char *passwordBytes = NULL;
	UInt32 passwordLength = 0;
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSString *username = [prefs objectForKey: @"username"];
	/*OSStatus keychainResult =*/ SecKeychainFindInternetPassword(NULL,
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
	NSString *password = [[NSString alloc] initWithBytes:passwordBytes length:passwordLength encoding:NSUTF8StringEncoding];
    if (passwordBytes != NULL) {
        SecKeychainItemFreeContent(NULL, passwordBytes);
    }
	
	return password;

}

@end
