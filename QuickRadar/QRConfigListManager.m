//
//  QRConfigListManager.m
//  QuickRadar
//
//  Created by Michael Herring on 2/24/13.
//
//

#import "QRConfigListManager.h"
#import "QRWebScraper.h"
#import "QRCachedRadarConfiguration.h"

@interface QRConfigListManager () {
    //config list manager uses a serial queue
    dispatch_queue_t _gcdQueue;
    NSArray *_availableConfigurations;
}

@property (readonly) NSString *radarPassword;

- (void)asyncUpdateAvailableConfigurations;

@end

@implementation QRConfigListManager

+ (QRConfigListManager *)sharedManager {
    static QRConfigListManager *sharedConfigListManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedConfigListManager = [[QRConfigListManager alloc] init];
        [sharedConfigListManager asyncUpdateAvailableConfigurations];
    });
    return sharedConfigListManager;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        _gcdQueue = dispatch_queue_create("com.quickradar.ConfigListQueue", NULL);

    }
    return self;
}

- (void)attemptToUpdateConfigurations {
    [self asyncUpdateAvailableConfigurations];
}

- (void)asyncUpdateAvailableConfigurations {
    dispatch_async(_gcdQueue, ^{
        //mostly follow the route that QRRadarSubmissionService uses, but then
        //request the Config Manager page instead once we're logged in. 
        NSError *err = nil;
        QRWebScraper *loginPage = [[QRWebScraper alloc] init];
		loginPage.URL = [NSURL URLWithString:@"https://bugreport.apple.com/cgi-bin/WebObjects/RadarWeb.woa/wa/signIn"];
		
		if (![loginPage fetch:&err])
		{
			//handle error
			return;
		}
		
		// ------- Parsing --------
		
		NSDictionary *loginPageXpaths = [NSDictionary dictionaryWithObjectsAndKeys:
										 @"//form[@name='appleConnectForm']/@action", @"action",
										 nil];
		
		NSDictionary *loginPageValues = [loginPage stringValuesForXPathsDictionary:loginPageXpaths error:&err];
		
		if (!loginPageValues)
		{
			//handle error
            return;
		}
		
		
		/**************************
		 * Page 2: JS bounce page *
		 **************************/
		
		
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		NSString *username = [prefs objectForKey: @"username"];
		NSString *password = [self radarPassword];
		
		NSURL *bouncePageURL = [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:[loginPageValues objectForKey:@"action"]];
		
		
		QRWebScraper *bouncePage = [[QRWebScraper alloc] init];
		bouncePage.URL = bouncePageURL;
		bouncePage.cookiesSource = loginPage;
		bouncePage.referrer = loginPage;
		bouncePage.HTTPMethod = @"POST";
		
		[bouncePage addPostParameter:username forKey:@"theAccountName"];
		[bouncePage addPostParameter:password forKey:@"theAccountPW"];
		[bouncePage addPostParameter:@"4" forKey:@"1.Continue.x"];
		[bouncePage addPostParameter:@"5" forKey:@"1.Continue.y"];
		[bouncePage addPostParameter:@"" forKey:@"theAuxValue"];
		
		if (![bouncePage fetch:&err])
		{
			//handle error
			return;
		}
		
		// ------- Parsing --------
		
		NSDictionary *bouncePageXpaths = [NSDictionary dictionaryWithObjectsAndKeys:
										  @"//form[@name='frmLinkMyOriginated']/@action", @"action",
										  @"//img[@alt='Alert']", @"alertIcon",
										  nil];
		
		NSDictionary *bouncePageValues = [bouncePage stringValuesForXPathsDictionary:bouncePageXpaths error:&err];
		
		if (!bouncePageValues ||
            [[bouncePageValues objectForKey:@"action"] length] == 0)
		{
			NSLog(@"Failed to load Configurations: Bounce page error.");
			return;
		}
        
		if ([[bouncePageValues objectForKey:@"alertIcon"] length] > 0)
		{
            //handle auth error
			return;
		}
		
		/***************************
		 * Page 3: Radar main page *
		 ***************************/
		
		
		NSURL *mainPageURL = [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:[bouncePageValues objectForKey:@"action"]];
		
		QRWebScraper *mainPage = [[QRWebScraper alloc] init];
		mainPage.URL = mainPageURL;
		mainPage.cookiesSource = bouncePage;
		mainPage.referrer = bouncePage;
		mainPage.HTTPMethod = @"POST";
		
		if (![mainPage fetch:&err])
		{
			//handle error
			return;
		}
        
        //------ Parsing ------
        
        NSDictionary *mainPageXpaths = [NSDictionary dictionaryWithObjectsAndKeys:
										@"//td[@class='navlink'][2]/a[1]/@href", @"URL",
										nil];
        
        NSDictionary *mainPageValues = [mainPage stringValuesForXPathsDictionary:mainPageXpaths error:&err];
        
        if (!mainPageValues) {
            //handle error
            return;
        }
        
        /*******************************
		 * Page 4: Config Manager Page *
		 ******************************/
        
        NSURL *configListURL = [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:[mainPageValues valueForKey:@"URL"]];
        
        
        QRWebScraper *configList = [[QRWebScraper alloc] init];
        configList.URL = configListURL;
        if ([configList fetch:&err]) {
            //these XPaths grab each configuration's name, as well as a link to the full text of the configuration.
            NSDictionary *configListXPaths = @{@"links":@"//td[@class='data01'][@width='60%']/a/@href",
                                               @"names":@"//td[@class='data01'][@width='60%']/a/u/text()"};
            NSDictionary *configListValues = [configList arrayValuesForXPathsDictionary:configListXPaths error:&err];
            if (configListValues) {
                NSArray *configs = [configListValues valueForKey:@"links"];
                NSArray *names = [configListValues valueForKey:@"names"];
                if (configs != nil) {
                    NSMutableArray *pulledConfigs = [NSMutableArray arrayWithCapacity:[configs count]];
                    
                    //The config links are good, so now we go forward and pull each config page, extracting the full config text out.
                    for (int i=0; i < [configs count]; ++i) {
                        NSXMLNode * href = [configs objectAtIndex:i];
                        NSXMLNode * name = [names objectAtIndex:i];
                        NSURL * nextConfigURL = [[NSURL URLWithString:@"https://bugreport.apple.com"] URLByAppendingPathComponent:[href stringValue]];
                        QRWebScraper *configPage = [[QRWebScraper alloc] init];
                        configPage.URL = nextConfigURL;
                        if ([configPage fetch:&err]) {
                            NSDictionary *configPageXPaths = @{@"contents":@"//form[@name='ConfigDetailed']//textarea[@name='29.26']/text()"};
                            NSDictionary *configPageValues = [configPage stringValuesForXPathsDictionary:configPageXPaths error:&err];
                            if (configPageValues) {
                                NSString *configContent = [configPageValues valueForKey:@"contents"];
                                NSString *configName = [name stringValue];
                                QRCachedRadarConfiguration *config = [[QRCachedRadarConfiguration alloc] initWithName:configName andContent:configContent];
                                [pulledConfigs addObject:config];
                            }
                        }
                        else {
                            NSLog(@"Failed to fetch %@",[href stringValue]);
                        }
                    }
                    _availableConfigurations = [pulledConfigs copy];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kQRConfigListUpdatedNotificationName object:self];
                }
            }
        }
    });
}

- (NSArray*)availableConfigurations {
    return _availableConfigurations?_availableConfigurations:@[];
}

- (NSString *)radarPassword {
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
	SecKeychainItemFreeContent(NULL, passwordBytes);
	
	return password;
    
}

@end
