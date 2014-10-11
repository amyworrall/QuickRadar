#import "NSString+URLEncoding.h"
@implementation NSString (URLEncoding)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding {
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
															   (CFStringRef)self,
															   NULL,
															   (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
															   CFStringConvertNSStringEncodingToEncoding(encoding)));
}

-(NSString *)xmlEncode;
{
	return (NSString *)CFBridgingRelease(CFXMLCreateStringByEscapingEntities(NULL, (__bridge CFStringRef)self, NULL));
}

-(NSString *)backslashQuotes;
{
	NSString *ret = [self stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
	ret = [self stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
	
	return ret;
}

@end