//
//  satellite_saver_2View.m
//  satellite-saver-2
//
//  Created by Rich Infante on 4/25/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

// GEOJSON FROM: https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_110m_coastline.geojson

#import "satellite_saver_2View.h"
#import "../rust/src/bridge.h"

@implementation satellite_saver_2View
@synthesize tleFetcher;

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        self.tleFetcher = [[TLEFetcher alloc] init];
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

- (void)drawMap {
    // Define the GPS Coordinate Space, relative to the screen.
    NSRect gpscoord = NSMakeRect(-180.0, -90.0, 360.0, 180.0);
    
    // Define the screen coordinate space.
    NSRect bounds = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    
    // Load world geo
    GeoJSONCollection * geo = [GeoJSONCollection world_geo];
    
    // Plot world geojson geometry.
    NSBezierPath *control0 = [NSBezierPath bezierPath];;
    for (int i = 0; i < [geo.features count]; i++) {
        GeoJSONFeature * feature = geo.features[i];
        
        [control0 removeAllPoints];
        
        // Just assume all geometry is a set of lines.
        for (int j = 0; j < [feature.geometry.coordinates count] - 1; j++) {
            GeoJSONGeometry * geometry = feature.geometry;
            NSPoint p0_init = [geometry point_atIndex:j];
            NSPoint p0 = [self convertCoordinateSpace:&p0_init fromSpace:&gpscoord toSpace: &bounds];
            NSPoint p1_init = [geometry point_atIndex:j+1];
            NSPoint p1 = [self convertCoordinateSpace:&p1_init fromSpace:&gpscoord toSpace: &bounds];
            [control0 moveToPoint: p0];
            [control0 lineToPoint: p1];
        }
        
        [[NSColor colorWithWhite:0.2 alpha:1.0] setStroke];
        [control0 setLineWidth: 1];
        [control0 stroke];
    }
    
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
    
    // Load TLE
    NSString* tle = [self.tleFetcher fetch_iss];
    NSString* name = [self.tleFetcher name];

    // Color for the track.
    NSColor* trackColor = [NSColor greenColor];
    
    // Get a cstring for the rust FFI.
    const char* _Nullable  tle_str = [tle cStringUsingEncoding:NSASCIIStringEncoding];
    NSFont* satelliteFont = [NSFont fontWithName:@"Menlo" size:12.0];
    
    if (tle_str == nil) {
        // Fill background.
        [[NSColor blackColor] setFill];
        NSRectFill(self.bounds);
        
        [self drawMap];
        
        NSString* loading = @"Loading Orbital Parameters...";
        [loading drawAtPoint:NSMakePoint(50, 50) withAttributes: @{
            NSForegroundColorAttributeName: [NSColor whiteColor],
            NSFontAttributeName: satelliteFont
        }];
        
        return;
    }
    
    // Run the predictions BEFORE any other rendering.
    struct Track t = run_prediction((char*) tle_str);
    
    
    // Fill background.
    [[NSColor blackColor] setFill];
    NSRectFill(self.bounds);
    
    [self drawMap];
    
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
    [trackColor setStroke];
    [trackColor setFill];
    [control1 setLineWidth: 1];
    [control1 stroke];
    
    // Convert current pos.
    NSPoint current_pos = NSMakePoint(t.current.longitude, t.current.latitude);
    NSPoint current_pos_screen = [self convertCoordinateSpace:&current_pos fromSpace:&gpscoord toSpace: &bounds];

    // Fill the marker rectangle.
    CGFloat boxRad = 5;
    if ([self isPreview]) {
        boxRad = 2.5;
    }

    NSRect marker_rect = NSMakeRect(current_pos_screen.x - boxRad, current_pos_screen.y - boxRad, boxRad * 2, boxRad * 2);
    NSRectFill(marker_rect);
    
    // Create a string for the current position info.
    NSString* formatted = [NSString stringWithFormat: @"%@\nlat: %f°\nlng: %f°\nalt: %f km", name, t.current.latitude, t.current.longitude, t.current.altitude];
    
    NSSize size = [formatted sizeWithAttributes: @{
      NSFontAttributeName: satelliteFont
    }];
    
    
    if (![self isPreview]) {
        // If it's too far to the right, switch to left aligned text.
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        CGFloat offset = boxRad * 4;
        if (current_pos_screen.x + boxRad * boxRad + size.width > self.bounds.origin.x + self.bounds.size.width) {
            style.alignment = NSTextAlignmentRight;
            offset = -offset + - size.width;
        }
        
        // Draw satellite info.
        [formatted drawAtPoint:NSMakePoint(current_pos_screen.x + offset, current_pos_screen.y + boxRad / 2 - size.height / 2) withAttributes: @{
            NSForegroundColorAttributeName: [NSColor whiteColor],
            NSFontAttributeName: satelliteFont,
            NSParagraphStyleAttributeName: style
        }];
    }

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
