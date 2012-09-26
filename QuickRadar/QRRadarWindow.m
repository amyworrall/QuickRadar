//
//  QRRadarWindow.m
//  QuickRadar
//
//  Created by Balázs Faludi on 14.08.12.
//
//

#import "QRRadarWindow.h"

@implementation QRRadarWindow

// Don't contrain window frame, so it can be moved off screen.
- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen {
	return frameRect;
}

@end
