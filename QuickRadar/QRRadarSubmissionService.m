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


#define NUM_PAGES 5.0

- (void)submitAsyncWithProgressBlock:(void (^)())progressBlock completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
//		NSLog(@"Starting radar");
//		sleep(5);
//		NSLog(@"Stopping radar");
//		completionBlock(YES, nil);
//		return;
		
		
		self.submissionStatusValue = submissionStatusInProgress;
		
		NSError *error = nil;
		
		
		
		// TEST
		/*
		self.radar.radarNumber = 27;
		
		self.progressValue = 1.0;
		self.submissionStatusValue = submissionStatusCompleted;
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			progressBlock();
			completionBlock(YES, nil);
		});
		return;
		*/

		
		
		/**********************
		 * Page 1: login page *
		 **********************/
		
        self.submissionStatusText = @"Fetching RadarWeb signin page";
		QRWebScraper *loginPage = [[QRWebScraper alloc] init];
		loginPage.URL = [NSURL URLWithString:@"https://bugreport.apple.com/cgi-bin/WebObjects/RadarWeb.woa/wa/signIn"];
		
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
		
		NSDictionary *loginPageXpaths = @{@"action": @"//form[@name='appleConnectForm']/@action"};
		
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
		 * Page 2: JS bounce page *
		 **************************/
		
        self.submissionStatusText = @"Signing into RadarWeb";
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		NSString *username = [prefs objectForKey: @"username"];
		NSString *password = [self radarPassword];
		
		NSURL *bouncePageURL = [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:loginPageValues[@"action"]];
		
		
		QRWebScraper *bouncePage = [[QRWebScraper alloc] init];
		bouncePage.URL = bouncePageURL;
		bouncePage.cookiesSource = loginPage;
		bouncePage.referrer = loginPage;
		bouncePage.HTTPMethod = @"POST";
		
		[bouncePage addPostParameter:username forKey:@"theAccountName"];
		[bouncePage addPostParameter:password forKey:@"theAccountPW"];
		[bouncePage addPostParameter:@"6" forKey:@"1.Continue.x"];
		[bouncePage addPostParameter:@"7" forKey:@"1.Continue.y"];
		[bouncePage addPostParameter:@"" forKey:@"theAuxValue"];
		
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
		
		NSDictionary *bouncePageXpaths = @{@"action": @"//form[@name='frmLinkMyOriginated']/@action",
										  @"alertIcon": @"//img[@alt='Alert']"};
		
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
		NSURL *mainPageURL = [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:bouncePageValues[@"action"]];
		
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
		
		// ------- Parsing --------
		
		NSDictionary *mainPageXpaths = @{@"URL": @"//td[@class='navlink'][1]/a[1]/@href"};
		
		NSDictionary *mainPageValues = [mainPage stringValuesForXPathsDictionary:mainPageXpaths error:&error];
		
		if (!mainPageValues)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		
		/***************************
		 * Page 4: New Ticket Page *
		 ***************************/
		
        self.submissionStatusText = @"Fetching RadarWeb new ticket page";
		NSURL *newTicketURL =  [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:mainPageValues[@"URL"]];
		
		QRWebScraper *newTicketPage = [[QRWebScraper alloc] init];
		newTicketPage.URL = newTicketURL;
		newTicketPage.cookiesSource = mainPage;
		newTicketPage.referrer = mainPage;
		newTicketPage.HTTPMethod = @"POST";
		
		if (![newTicketPage fetch:&error])
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
		
		// ------- Parsing --------
		
		NSString *trimmedClassification = [self.radar.classification stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		NSDictionary *newTicketPageXpaths = @{@"action": @"//form[@name='BugReportDetail']/@action",
											 @"newProbName": @"//input[@id='probTitleNewProb']/@name",
											 @"initialPopulateFlagName": @"//input[@id='initialPopulateFlag']/@name",
											 @"isItReproducibleName": @"//select[@id='reproducibleNewProb']/@name",
											 @"reproducibleNumber": [NSString stringWithFormat:@"//select[@id='reproducibleNewProb'][1]/option[text()=\"%@\"]/@value", self.radar.reproducible],
											 @"refreshCountName": @"//input[@id='refreshCount']/@name",
											 @"refreshCountValue": @"//input[@id='refreshCount']/@value",
											 @"configEmptyFlagName": @"//input[@id='configEmptyFlag']/@name",
											 @"configInformationName": @"//input[@id='configInformation']/@name",
											 @"configIDName": @"//input[@id='confgID']/@name",
											 @"configInfoTextareaName": @"//textarea[@id='ConfigInfo']/@name",
											 @"productListNumber": [NSString stringWithFormat:@"//select[@id='prodList'][1]/option[text()='%@']/@value", self.radar.product],
											 @"classificationNumber": [NSString stringWithFormat:@"//select[@id='classList']/option[text()='%@']/@value", trimmedClassification]};
		
		
		NSDictionary *newTicketPageValues = [newTicketPage stringValuesForXPathsDictionary:newTicketPageXpaths error:&error];
		
		if (!newTicketPageValues)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		
		// This is a fudge until I write an Xpath that'll get this.
		NSString *appendNewConfigName =  @"61.103.49"; 
		
		
		/*******************************
		 * Page 5: Bug Submission Page *
		 *******************************/
		
        self.submissionStatusText = @"Submitting bug to RadarWeb";
		NSURL *bugSubmissionURL =  [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:newTicketPageValues[@"action"]];
		
		QRWebScraper *bugSubmissionPage = [[QRWebScraper alloc] init];
		bugSubmissionPage.URL = bugSubmissionURL;
		bugSubmissionPage.cookiesSource = newTicketPage;
		bugSubmissionPage.referrer = newTicketPage;
		bugSubmissionPage.HTTPMethod = @"POST";
		bugSubmissionPage.sendMultipartFormData = YES;
		
		/* Sets up all the fields necessary for submission.
		 * Order is really important here: RadarWeb borks if it gets them in the wrong order. */
		[bugSubmissionPage addPostParameter:newTicketPageValues[@"refreshCountValue"] forKey:newTicketPageValues[@"refreshCountName"]];
		[bugSubmissionPage addPostParameter:@"No" forKey:@"formatAddFlag"];
		[bugSubmissionPage addPostParameter:self.radar.version forKey:@"configSummary"];
		[bugSubmissionPage addPostParameter:@"flag" forKey:newTicketPageValues[@"configEmptyFlagName"]];
		[bugSubmissionPage addPostParameter:@"No" forKey:@"iPhoneFlag"];
		[bugSubmissionPage addPostParameter:self.radar.title forKey:newTicketPageValues[@"newProbName"]];
		[bugSubmissionPage addPostParameter:newTicketPageValues[@"productListNumber"] forKey:@"prodList"];
		[bugSubmissionPage addPostParameter:newTicketPageValues[@"classificationNumber"] forKey:@"classList"];
		[bugSubmissionPage addPostParameter:newTicketPageValues[@"reproducibleNumber"] forKey:newTicketPageValues[@"isItReproducibleName"]];
		[bugSubmissionPage addPostParameter:self.radar.body forKey:@"probDesc"];
		[bugSubmissionPage addPostParameter:@"" forKey:newTicketPageValues[@"configInformationName"]];
		[bugSubmissionPage addPostParameter:[NSData data] forKey:newTicketPageValues[@"configIDName"]];
		[bugSubmissionPage addPostParameter:@"WONoSelectionString" forKey:appendNewConfigName];
		[bugSubmissionPage addPostParameter:@"" forKey:newTicketPageValues[@"configInfoTextareaName"]];
		[bugSubmissionPage addPostParameter:@"No" forKey:newTicketPageValues[@"initialPopulateFlagName"]];
		[bugSubmissionPage addPostParameter:[NSData data] forKey:@"__DEFAULT__FILE__1__"];
		[bugSubmissionPage addPostParameter:@"25" forKey:@"Save.x"];
		[bugSubmissionPage addPostParameter:@"16" forKey:@"Save.y"];
		
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
		
		NSDictionary *bugSubmissionPageXpaths = @{@"radarNumber": @"(//font)[6]"};
		
		NSDictionary *bugSubmissionPageValues = [bugSubmissionPage stringValuesForXPathsDictionary:bugSubmissionPageXpaths error:&error];
		
		if (!bugSubmissionPageValues)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{ 
				self.submissionStatusValue = submissionStatusFailed;
				completionBlock(NO, error);
			});
			return;
		}
		
		NSInteger radarNumberResult = [bugSubmissionPageValues[@"radarNumber"] integerValue];
		
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
