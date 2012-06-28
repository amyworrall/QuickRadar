//
//  QRRadar.m
//  QuickRadar
//
//  Created by Amy Worrall on 26/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QRRadar.h"

@interface QRRadar ()

@property (nonatomic, strong) NSMutableDictionary *serviceSpecificProperties;

@end

@implementation QRRadar

@synthesize product = _product;
@synthesize version = _version;
@synthesize classification = _classification;
@synthesize reproducible = _reproducible;
@synthesize title = _title;
@synthesize body = _body;
@synthesize radarNumber = _radarNumber;
@synthesize serviceSpecificProperties = _serviceSpecificProperties;


- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	if (!self.serviceSpecificProperties)
	{
		self.serviceSpecificProperties = [NSMutableDictionary dictionary];
	}
	
	[self.serviceSpecificProperties setObject:value forKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return [self.serviceSpecificProperties objectForKey:key];
}



@end
