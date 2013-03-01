//
//  QRCachedRadarConfiguration.m
//  QuickRadar
//
//  Created by Michael Herring on 2/24/13.
//
//

#import "QRCachedRadarConfiguration.h"

@interface QRCachedRadarConfiguration ()

@property (nonatomic, strong) NSString *name;
@property (assign) NSString *content;

@end

@implementation QRCachedRadarConfiguration

- (id)initWithName:(NSString*)name andContent:(NSString*)content {
    self = [super init];
    if (self != nil) {
        [self setName:name];
        [self setContent:content];
    }
    return self;
}

@end
