//
//  QRFileWell.h
//  QuickRadar
//
//  Created by Amy Worrall on 10/10/2014.
//
//

#import <Cocoa/Cocoa.h>

@interface QRFileWell : NSControl

@property (nonatomic, assign) NSCellImagePosition imagePosition;

@property (nonatomic, copy) NSURL *URL; // The file currently represented by the control

@end
