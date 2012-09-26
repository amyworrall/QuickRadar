//
//  QRAppListTableCellView.m
//  RunningApps
//
//  Created by Balázs Faludi on 18.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//

#import "QRAppListTableCellView.h"

@interface QRAppListTableCellView ()

@property (nonatomic) IBOutlet NSTextField *appInfoField;
@property (nonatomic) IBOutlet NSImageView *iconView;
@property (nonatomic) IBOutlet NSImageView *warningView;

@end

@implementation QRAppListTableCellView

- (void)updateText {
	// Put it in an attributed string. Version numbers will be gray (or light gray when selected)
	NSString *text = self.appName;
	if (!text) text = @"Unknown app";
	if (self.appVersion) text = [text stringByAppendingFormat:@" %@", self.appVersion];
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
	
	NSRange nameRange = NSMakeRange(0, self.appName.length);
	NSRange versionRange = NSMakeRange(self.appName.length, text.length - self.appName.length);

	NSColor *nameColor = [NSColor blackColor];
	NSColor *versionColor = [NSColor grayColor];
	if (self.backgroundStyle == NSBackgroundStyleDark) {
		nameColor = [NSColor whiteColor];
		versionColor = [NSColor colorWithCalibratedWhite:0.9f alpha:1.0f];
	}
	
	[attributedString addAttribute:NSForegroundColorAttributeName value:nameColor range:nameRange];
	[attributedString addAttribute:NSForegroundColorAttributeName value:versionColor range:versionRange];
	self.appInfoField.attributedStringValue = attributedString;
}

- (void)setAppName:(NSString *)appName {
	_appName = appName;
	[self updateText];
}

- (void)setAppVersion:(NSString *)appVersion {
	_appVersion = appVersion;
	[self updateText];
}

- (void)setAppIcon:(NSImage *)appIcon {
	self.iconView.image = appIcon;
}

- (void)setShowsWarning:(BOOL)showsWarning {
	self.warningView.hidden = !showsWarning;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
	[super setBackgroundStyle:backgroundStyle];
	[self updateText];
}


@end
