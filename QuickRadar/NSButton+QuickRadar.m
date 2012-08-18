//
//  NSControl+QuickRadar.m
//  QuickRadar
//
//  Created by Balázs Faludi on 18.08.12.
//
//

#import "NSButton+QuickRadar.h"

@implementation NSButton (QuickRadar)

- (void)turnOff {
	[self highlight:NO];
}

- (void)turnOn {
	[self highlight:YES];
}

- (void)blink {
	[self turnOn];
	[self performSelector:@selector(turnOff) withObject:nil afterDelay:0.1];
}

- (void)blinkTwice {
	[self turnOn];
	[self performSelector:@selector(turnOff) withObject:nil afterDelay:0.1];
	[self performSelector:@selector(turnOn) withObject:nil afterDelay:0.2];
	[self performSelector:@selector(turnOff) withObject:nil afterDelay:0.3];
}

@end
