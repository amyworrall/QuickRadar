//
//  QRFileDuplicateWindowController.m
//  QuickRadar
//
//  Created by Amy Worrall on 19/02/2013.
//
//

#import "QRFileDuplicateWindowController.h"
#import "QRRadar.h"
#import "AppDelegate.h"

@interface QRFileDuplicateWindowController ()

@end

@implementation QRFileDuplicateWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)cancel:(id)sender
{
	[self close];
}


- (void)OK:(id)sender
{
	if (self.textField.stringValue.length == 0)
	{
		return;
	}
	
	[self.spinner startAnimation:self];
	[self.okButton setEnabled:NO];
	
	NSString *radarNum = self.textField.stringValue;
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://openradar.appspot.com/api/radar?number=%@", radarNum]]];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	
	[NSURLConnection sendAsynchronousRequest:req queue:queue completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
		NSDictionary *mainDict = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
		NSDictionary *radarDict = [mainDict objectForKey:@"result"];
		
		QRRadar *radar = [[QRRadar alloc] init];
		radar.title = [radarDict objectForKey:@"title"];
		radar.classification = [radarDict objectForKey:@"classification"];
		radar.version = [radarDict objectForKey:@"product_version"];
		radar.reproducible = [radarDict objectForKey:@"reproducible"];
		radar.product = [radarDict objectForKey:@"product"];
		radar.radarNumber = radarNum;
		
		NSString *body = [radarDict objectForKey:@"description"];
		radar.body = [NSString stringWithFormat:@"This is a duplicate of rdar://%li\n\n%@", (long)radar.radarNumber, (body!=nil)?body:@""];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			self.textField.stringValue = @"";
			[self.spinner stopAnimation:self];
			[self.okButton setEnabled:YES];
			[self close];
			[(AppDelegate*)[NSApp delegate] newBugWithRadar:radar];
		});
		
	}];

}

@end
