//
//  satellite_saver_2View.m
//  satellite-saver-2
//
//  Created by Rich Infante on 4/25/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

#import "satellite_saver_2View.h"
#import "../rust/src/bridge.h"

@implementation satellite_saver_2View

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1.0];
    }
    return self;
}

// Convert from one coordinate space to another.
-(NSPoint) convertCoordinateSpace: (NSPoint*)point fromSpace:(NSRect*) from toSpace:(NSRect*) to{
    return NSMakePoint((((point->x - from->origin.x) / from->size.width) * to->size.width) + to->origin.x,
                       (((point->y - from->origin.y) / from->size.height) * to->size.height) + to->origin.y);
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    if (![self isPreview]) {
//        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    }

    // Define the GPS Coordinate Space, relative to the screen.
    NSRect gpscoord = NSMakeRect(-180.0, -90.0, 360.0, 180.0);
    
    // Define the screen coordinate space.
    NSRect bounds = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    
    // Save a TLE.
    NSString*tle = @"ISS (ZARYA)\n1 25544U 98067A   19115.51040572  .00001427  00000-0  30272-4 0  9993\n2 25544  51.6409 263.0334 0001111 214.7214 223.5370 15.52589973167070";
    
    // Name
    NSString* name = @"ISS (ZARYA)";
    
    
    // Get a cstring for the rust FFI.
    const char* _Nullable  tle_str = [tle cStringUsingEncoding:NSASCIIStringEncoding];
    
    if (tle_str == nil) {
        // Fill background.
        [[NSColor blackColor] setFill];
        NSRectFill(self.bounds);
        
        return;
    }
    
    // Run the predictions
    struct Track t = run_prediction((char*) tle_str);
    
    // Fill background.
    [[NSColor blackColor] setFill];
    NSRectFill(self.bounds);
    
    // Create a bezier path for the space track.
    NSBezierPath *control1 = [NSBezierPath bezierPath];
    for (int i = 0; i < 59; i++) {
        
        // Convert p0 and p1 (consecutive points) to the coord space.
        NSPoint p0_init = NSMakePoint(t.track[i].longitude, t.track[i].latitude);
        NSPoint p0 = [self convertCoordinateSpace:&p0_init fromSpace:&gpscoord toSpace: &bounds];
        NSPoint p1_init = NSMakePoint(t.track[i+1].longitude, t.track[i+1].latitude);
        NSPoint p1 = [self convertCoordinateSpace:&p1_init fromSpace:&gpscoord toSpace: &bounds];
        [control1 moveToPoint:p0];
        
        // Find distance
        float dist = sqrt(pow(p0.x - p1.x, 2.0) + pow(p0.y - p1.y, 2.0));
        
        // If they're very far away, it's likely because it wraps the screen.
        // To prevent the bezier curve making a line across, move instead of line.
        if (dist < 120) {
            [control1 lineToPoint:p1];
        } else {
            [control1 moveToPoint:p1];
        }
        
    }
    
    // Fill the path.
    [[NSColor greenColor] setStroke];
    [[NSColor greenColor] setFill];
    [control1 setLineWidth: 1];
    [control1 stroke];
    
    // Convert current pos.
    NSPoint current_pos = NSMakePoint(t.current.longitude, t.current.latitude);
    NSPoint current_pos_screen = [self convertCoordinateSpace:&current_pos fromSpace:&gpscoord toSpace: &bounds];

    // Fill the marker rectangle.
    CGFloat boxRad = 5;
    NSRect marker_rect = NSMakeRect(current_pos_screen.x - boxRad, current_pos_screen.y - boxRad, boxRad * 2, boxRad * 2);
    NSRectFill(marker_rect);
    
    // Create a string for the current position info.
    NSString* formatted = [NSString stringWithFormat: @"%@\nlat: %f°\nlng: %f°\nalt: %f km", name, t.current.latitude, t.current.longitude, t.current.altitude];
    
    // Draw satellite info.
    [formatted drawAtPoint:NSMakePoint(current_pos_screen.x + boxRad * 4, current_pos_screen.y) withAttributes: @{
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:12.0]
    }];

    [self setNeedsDisplay:YES];
}

- (void)animateOneFrame
{
    [self setNeedsDisplay:YES];
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
