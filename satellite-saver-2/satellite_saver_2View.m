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
@synthesize configSheet;
@synthesize enableDetailedLabels, enableDetailedLabelsField;
@synthesize enableLabelBackgrounds, enableLabelBackgroundsField;
@synthesize enableTracks, enableTracksField;
@synthesize filterSatellites, filterSatellitesField;
@synthesize customURL, customURLField;

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        self.tleFetcher = [[TLEFetcher alloc] init];
        [self setAnimationTimeInterval:1.0];
        
        ScreenSaverDefaults *defaults;
        defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"SatelliteSaver"];
        
        // Register our default values
        [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                    @NO, @"enableLabelBackgrounds",
                                    @YES, @"enableDetailedLabels",
                                    @YES, @"enableTracks",
                                    @"ISS (ZARYA)", @"filterSatellites",
                                    @"https://celestrak.richinfante.com/stations.txt", @"customURL",
                                    nil]];
        
        
        // Load defaults
        self.enableLabelBackgrounds = [defaults boolForKey:@"enableLabelBackgrounds"];
        self.enableDetailedLabels = [defaults boolForKey:@"enableDetailedLabels"];
        self.enableTracks = [defaults boolForKey:@"enableTracks"];
        self.customURL = [defaults stringForKey:@"customURL"];
        self.filterSatellites = [defaults stringForKey:@"filterSatellites"];
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

- (NSArray<NSBezierPath*>*)drawMap {
    // Define the GPS Coordinate Space, relative to the screen.
    NSRect gpscoord = NSMakeRect(-180.0, -90.0, 360.0, 180.0);
    
    // Define the screen coordinate space.
    NSRect bounds = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    
    // Load world geo
    GeoJSONCollection * geo = [GeoJSONCollection world_geo];
    
    NSMutableArray<NSBezierPath*>* paths = [[NSMutableArray alloc] init];

    // Plot world geojson geometry.
    for (int i = 0; i < [geo.features count]; i++) {
        GeoJSONFeature * feature = geo.features[i];
        
        NSBezierPath *control0 = [NSBezierPath bezierPath];;
        
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
        
        [paths addObject:control0];
    }
    
    return paths;
    
}

-(void)drawMarker:(TLE*) tle {
    NSRect gpscoord = NSMakeRect(-180.0, -90.0, 360.0, 180.0);
    
    // Define the screen coordinate space.
    NSRect bounds = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    
    struct TrackPoint current = [tle get_current_point];
    // Convert current pos.
    NSPoint current_pos = NSMakePoint(current.longitude, current.latitude);
    NSPoint current_pos_screen = [self convertCoordinateSpace:&current_pos fromSpace:&gpscoord toSpace: &bounds];
    
    // Fill the marker rectangle.
    CGFloat boxRad = 5;
    if ([self isPreview]) {
        boxRad = 2.5;
    }
    
    [[tle trackColor] setFill];
    
    NSRect marker_rect = NSMakeRect(current_pos_screen.x - boxRad, current_pos_screen.y - boxRad, boxRad * 2, boxRad * 2);
    NSRectFill(marker_rect);
}

-(void)drawMarkerText:(TLE*) tle {
    NSRect gpscoord = NSMakeRect(-180.0, -90.0, 360.0, 180.0);
    
    // Define the screen coordinate space.
    NSRect bounds = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    NSFont* satelliteFont = [NSFont fontWithName:@"Menlo" size:12.0];
    
    struct TrackPoint current = [tle get_current_point];
    // Convert current pos.
    NSPoint current_pos = NSMakePoint(current.longitude, current.latitude);
    NSPoint current_pos_screen = [self convertCoordinateSpace:&current_pos fromSpace:&gpscoord toSpace: &bounds];
    
    // Fill the marker rectangle.
    CGFloat boxRad = 5;
    if ([self isPreview]) {
        boxRad = 2.5;
    }
    
    // Create a string for the current position info.
    NSString* formatted;
    
    if (!self.enableDetailedLabels) {
        formatted = [tle.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else {
        formatted = [NSString stringWithFormat: @"%@\nlat: %f°\nlng: %f°\nalt: %f km", tle.name, current.latitude, current.longitude, current.altitude];
    }
    
    NSSize size = [formatted sizeWithAttributes: @{
         NSFontAttributeName: satelliteFont
    }];
    
    
    // If it's too far to the right, switch to left aligned text.
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    CGFloat offset = boxRad * 4;
    if (current_pos_screen.x + boxRad * boxRad + size.width > self.bounds.origin.x + self.bounds.size.width) {
        style.alignment = NSTextAlignmentRight;
        offset = -offset + - size.width;
    }
    
    NSPoint atPoint = NSMakePoint(current_pos_screen.x + offset, current_pos_screen.y + boxRad / 2 - size.height / 2);
    
    if (self.enableLabelBackgrounds) {
        NSRect textBg = NSMakeRect(atPoint.x - 2, atPoint.y - 2, size.width + 4, size.height + 4);
        
        [[NSColor blackColor] setFill];
        [[NSColor darkGrayColor] setStroke];
        NSBezierPath* outline = [NSBezierPath bezierPathWithRect:textBg];
        [outline stroke];
        NSRectFill(textBg);
    }
    
    // Draw satellite info.
    [formatted drawAtPoint:atPoint withAttributes: @{
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSFontAttributeName: satelliteFont,
        NSParagraphStyleAttributeName: style
    }];
}

-(void)drawTrack:(TLE*) tle {
    NSRect gpscoord = NSMakeRect(-180.0, -90.0, 360.0, 180.0);
    
    // Define the screen coordinate space.
    NSRect bounds = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    NSColor* trackColor = [tle trackColor];
    
    // Create a bezier path for the space track.
    NSBezierPath *control1 = [NSBezierPath bezierPath];
    struct Track t = [tle get_track];
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
        if (dist < 180) {
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
}

- (void)drawRect:(NSRect)rect
{
    
    NSArray* tles = [self.tleFetcher get_tlesFromURL:self.customURL filteringNames:self.filterSatellites];
    
    // For each loaded TLE, setup a new track.
    for (TLE* tle in tles) {
        const char* _Nullable  tle_str_lines = [tle.lines cStringUsingEncoding:NSASCIIStringEncoding];
        struct Track t = run_prediction((char*) tle_str_lines);
        [tle set_trackWithTrack:t];
    }
    
    // Fill background
    [[NSColor blackColor] setFill];
    NSRectFill(self.bounds);
    
    // Draw map
    [self drawMap];
    
    if (self.enableTracks) {
        // Draw track
        for (TLE* tle in [tles reverseObjectEnumerator]) {
            [self drawTrack: tle];
        }
    }
    
    // Draw markers.
    for (TLE* tle in [tles reverseObjectEnumerator]) {
        [self drawMarker: tle];
    }

    if (![self isPreview]) {
        // Draw marker texts
        for (TLE* tle in [tles reverseObjectEnumerator]) {
            [self drawMarkerText: tle];
        }
    }

    [self setNeedsDisplay:YES];
}

- (void)animateOneFrame
{
    [self setNeedsDisplay:YES];
    return;
}

+ (BOOL)performGammaFade {
    return NO;
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow*)configureSheet
{
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"SatelliteSaver"];
    
    if (self.configSheet == nil)
    {
        NSArray *topLevelObjects;
        
        if (![[NSBundle bundleForClass:[self class]] loadNibNamed:@"ConfigureSheet" owner:self topLevelObjects:&topLevelObjects])
        {
            NSLog( @"Failed to load configure sheet." );
            NSBeep();
        }
    }
    
    // Initialize elements to saved values.
    [self.enableTracksField setState: [defaults boolForKey:@"enableTracks"] ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.enableLabelBackgroundsField setState: [defaults boolForKey:@"enableLabelBackgrounds"] ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.enableDetailedLabelsField setState: [defaults boolForKey:@"enableDetailedLabels"] ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.customURLField setStringValue: [defaults stringForKey:@"customURL"]];
    [self.filterSatellitesField setStringValue: [defaults stringForKey:@"filterSatellites"]];
    
    return self.configSheet;
}

- (IBAction)configSheetCancelAction:(id)sender {
    if ([NSWindow respondsToSelector:@selector(endSheet:)])
    {
        [[self.configSheet sheetParent] endSheet:self.configSheet returnCode:NSModalResponseCancel];
    } else {
        [[NSApplication sharedApplication] endSheet:self.configSheet];
    }
}

- (IBAction)configSheetOKAction:(id)sender {

    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"SatelliteSaver"];
    
    // Load defaults into current view.
    self.enableDetailedLabels = [self.enableDetailedLabelsField state] == NSControlStateValueOn;
    self.enableLabelBackgrounds = [self.enableLabelBackgroundsField state] == NSControlStateValueOn;
    self.customURL = [self.customURLField stringValue];
    self.filterSatellites = [self.filterSatellitesField stringValue];
    self.enableTracks = [self.enableTracksField state] == NSControlStateValueOn;

    // Reload defaults
    [defaults setBool: self.enableDetailedLabels forKey:@"enableDetailedLabels"];
    [defaults setBool: self.enableLabelBackgrounds forKey:@"enableLabelBackgrounds"];
    [defaults setBool: self.enableTracks forKey:@"enableTracks"];
    [defaults setValue: self.customURL forKey:@"customURL"];
    [defaults setValue: self.filterSatellites forKey:@"filterSatellites"];
    [defaults synchronize];
    
    // Issue refresh of TLEs.
    [self.tleFetcher reload];
    
    // Cancel the sheet.
    [self configSheetCancelAction:sender];
}

@end
