//
//  QRCachedRadarConfiguration.h
//  QuickRadar
//
//  Created by Michael Herring on 2/24/13.
//
//

#import <Foundation/Foundation.h>

@interface QRCachedRadarConfiguration : NSObject

@property (readonly) NSString *name;
@property (readonly) NSString *content;

- (id)initWithName:(NSString*)name andContent:(NSString*)content;

@end
