//
//  NSXMLNode+Additions.h
//  Saisier
//
//  Created by Amy Worrall on 09/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import "DDXML.h"
#endif

@interface NSXMLNode (Additions)

- (NSXMLNode*)firstNodeForXPath:(NSString*)xpath;
- (NSXMLElement*)firstElementForXPath:(NSString*)xpath;

@end
