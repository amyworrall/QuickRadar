//
//  QRAppListOutlineView.m
//  QuickRadar
//
//  Created by Nicholas Riley on 3/31/13.
//
//

#import "QRAppListOutlineView.h"

@implementation QRAppListOutlineView

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
{
    if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"\r"]) {
        [NSApp sendAction:[self action] to:[self target] from:self];
        return YES;
    }
    
    return [super performKeyEquivalent:theEvent];
}

@end
