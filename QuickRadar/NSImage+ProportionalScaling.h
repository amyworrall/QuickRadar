//
//  NSImage+ProportionalScaling.h
//  QuickRadar
//
//  Created by Amy Worrall on 10/10/2014.
//
//

// From http://theocacao.com/document.page/498

#import <Cocoa/Cocoa.h>

@interface NSImage (ProportionalScaling)

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize;

@end
