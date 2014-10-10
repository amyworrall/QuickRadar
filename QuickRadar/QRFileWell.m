//
//  QRFileWell.m
//  QuickRadar
//
//  Created by Amy Worrall on 10/10/2014.
//
//

#import "QRFileWell.h"
#import "NSImage+ProportionalScaling.h"

@interface QRFileWell ()
@property (nonatomic, assign) NSInteger cachedDragOperation;

@property (nonatomic, assign) BOOL hovering;
@end



@implementation QRFileWell

#pragma mark - Intitialisation

- (id)initWithFrame:(NSRect)frameRect {
	if (self = [super initWithFrame:frameRect]) {
		[self setup];
	}
	return self;
}

- (void)awakeFromNib {
	[self setup];
}

- (void)setup {
	[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

#pragma mark - Options

- (void)setImagePosition:(NSCellImagePosition)imagePosition {
	_imagePosition = imagePosition;
	[self setNeedsDisplay:YES];
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
	if (!self.URL) {
		[self drawEmptyState];
	} else {
		[self drawFullState];
	}
}

- (void)drawEmptyState
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 2, 2) xRadius:5 yRadius:5];
	[path setLineWidth:3];
	
	
	CGFloat array[2];
	array[0] = 8.0; //segment painted with stroke color
	array[1] = 4.0; //segment not painted with a color
 
	[path setLineDash: array count: 2 phase: 1.0];
	
	if (self.hovering) {
		[[NSColor lightGrayColor] set];
		[path fill];
	}
	
	[[NSColor grayColor] set];
	[path stroke];
	
	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style setAlignment:NSCenterTextAlignment];
	NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,
								 NSForegroundColorAttributeName : [NSColor grayColor],
								 NSFontAttributeName : [NSFont boldSystemFontOfSize:13.0]};
	
	NSString *message = @"Choose a file to attach";
	[self drawString:message verticallyCentredInRect:self.bounds withAttributes:attributes];
}

- (void)drawFullState
{
	NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:self.URL.path];
	NSImage *scaledImage = [image imageByScalingProportionallyToSize:NSMakeSize(self.bounds.size.height, self.bounds.size.height)];
	[scaledImage drawInRect:NSMakeRect(0, 0, self.bounds.size.height, self.bounds.size.height)];
	
	NSString *filename = [self.URL lastPathComponent];
	[self drawString:filename verticallyCentredInRect:NSMakeRect(self.bounds.size.height, 0, self.bounds.size.width - self.bounds.size.height, self.bounds.size.height) withAttributes:@{}];
}

- (void)drawString:(NSString*)string verticallyCentredInRect:(NSRect)rect withAttributes:(NSDictionary*)attributes {
	NSSize size = [string sizeWithAttributes:attributes];
	[string drawInRect:NSMakeRect(rect.origin.x, rect.origin.y + (rect.size.height - size.height) / 2.0, rect.size.width, size.height) withAttributes:attributes];
}

#pragma mark - Dragging

- (NSDragOperation) draggingEntered:sender {
	NSPasteboard   *pboard;
	
	self.cachedDragOperation      = NSDragOperationNone;
	pboard    = [sender draggingPasteboard];
	
	// we don't acept drags if we are the provider!!
	if ([sender draggingSource] == self) return NSDragOperationNone;
	
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		self.hovering = YES;
		[self setNeedsDisplay:YES];
		
		// we'll copy or link depending on the intent of the dragging source:
		self.cachedDragOperation = [sender draggingSourceOperationMask];
	}
	return self.cachedDragOperation;
}

- (NSDragOperation) draggingUpdated:sender {
	return self.cachedDragOperation;
}

- (void) draggingExited:sender
{
	// the user has exited -> clean up:
	if ([sender draggingSource] != self)  {
		self.hovering = NO;
		[self setNeedsDisplay:YES];
		
		self.cachedDragOperation = NSDragOperationNone;
	}
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender {
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSString *path = [[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0];
	self.URL = [NSURL fileURLWithPath:path];
	return YES;
}

- (void)setURL:(NSURL *)URL {
	_URL = URL;
	[self setNeedsDisplay:YES];
}





@end
