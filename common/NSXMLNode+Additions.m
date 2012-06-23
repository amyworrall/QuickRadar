//
//  NSXMLNode+Additions.m
//  Saisier
//
//  Created by Amy Worrall on 09/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSXMLNode+Additions.h"

@implementation NSXMLNode (Additions)

- (NSXMLNode*)firstNodeForXPath:(NSString*)xpath;
{
	NSError *error;
	
	NSArray *nodes = [self nodesForXPath:xpath error:&error];
	
	if (!nodes || error)
	{
		return nil;
	}
	
	if (nodes.count == 0)
	{
		return nil;
	}
	
	return [nodes objectAtIndex:0];
}

- (NSXMLElement*)firstElementForXPath:(NSString *)xpath
{
	NSXMLNode *n = [self firstNodeForXPath:xpath];
	
	if ([n isKindOfClass:[NSXMLElement class]])
	{
		return (NSXMLElement*)n;
	}
	return nil;
}

@end
