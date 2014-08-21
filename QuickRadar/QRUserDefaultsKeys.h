//
//  QRUserDefaultsKeys.h
//  QuickRadar
//
//  Created by Amy Worrall on 03/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#define QRShowInDockKey @"QRShowInDock"
#define QRShowInStatusBarKey @"QRShowInStatusBar"
#define QRHandleRdarURLsKey @"QRHandleRdarURLs"
#define QRAppDotNetIncludeRdarLinksKey @"appDotNetIncludeRdarLinks"
#define QRWindowLevelKey @"QRWindowLevel"

typedef enum {
	rdarURLsMethodDoNothing = 1,
	rdarURLsMethodOpenRadar = 2,
	rdarURLsMethodFileDuplicate = 0,
} rdarURLsMethod;