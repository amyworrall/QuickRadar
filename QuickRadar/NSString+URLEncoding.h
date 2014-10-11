#import <Foundation/Foundation.h>
@interface NSString (URLEncoding)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
-(NSString *)xmlEncode;
-(NSString *)backslashQuotes;
@end