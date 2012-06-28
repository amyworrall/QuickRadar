//
//  NSXMLNode+Additions.h
//  Saisier
//
//  Created by Amy Worrall on 09/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSXMLNode (Additions)

- (NSXMLNode*)firstNodeForXPath:(NSString*)xpath;
- (NSXMLElement*)firstElementForXPath:(NSString*)xpath;

- (NSXMLNode*)firstNodeForXPath:(NSString*)xpath error:(NSError**)error;
- (NSXMLElement*)firstElementForXPath:(NSString*)xpath error:(NSError**)error;

@end
