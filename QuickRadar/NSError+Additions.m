//
//  NSError+Additions.m
//  QuickRadar
//
//  Created by Amy Worrall on 03/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSError+Additions.h"
#import "QRSubmissionService.h"

@implementation NSError (Additions)

+ (NSError*)authenticationErrorWithServiceIdentifier:(NSString*)serviceIdentifier underlyingError:(NSError*)error;
{
	
	NSDictionary *services = [QRSubmissionService services];
	Class service = [services objectForKey:serviceIdentifier];
	NSString *name = [service name];
	
	NSString *message = [NSString stringWithFormat:@"The \"%@\" service reported an authentication failure. Are your credentials correct?", name];
	NSString *title = @"Authentication failure";
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  message, NSLocalizedRecoverySuggestionErrorKey,
							  title, NSLocalizedDescriptionKey,
							  error, NSUnderlyingErrorKey, // This one might be nil, so it's last
							  
							  nil];
	
	NSError *newError = [NSError errorWithDomain:QRErrorDomain code:QRErrorCodeAuthenticationError userInfo:userInfo];
	return newError;
}

@end
