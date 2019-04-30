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
#import "Satellite-Swift.h"

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
                                    @"00ff00", @"trackColor",
                                    @"000000", @"backgroundColor",
                                    @"333333", @"mapColor",
                                    @"ffffff", @"textColor",
                                    nil]];
        
        [self loadDefaults];
    }
    return self;
}


- (IBAction)restoreDefaults:(id)sender {
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"SatelliteSaver"];
    [defaults setBool:NO forKey:@"enableLabelBackgrounds"];
    [defaults setBool:YES forKey:@"enableDetailedLabels"];
    [defaults setBool:YES  forKey: @"enableTracks"];
    [defaults setValue:@"ISS (ZARYA)" forKey:@"filterSatellites"];
    [defaults setValue:@"https://celestrak.richinfante.com/stations.txt" forKey:@"customURL"];
    [defaults setValue:@"00ff00" forKey:@"trackColor"];
    [defaults setValue:@"000000" forKey:@"backgroundColor"];
    [defaults setValue:@"333333" forKey:@"mapColor"];
    [defaults setValue:@"ffffff" forKey:@"textColor"];
    [defaults synchronize];
    
    [self loadDefaults];
    [self loadDefaultsForEditing];
}

-(void) loadDefaults {
    // Load defaults
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"SatelliteSaver"];
    self.enableLabelBackgrounds = [defaults boolForKey:@"enableLabelBackgrounds"];
    self.enableDetailedLabels = [defaults boolForKey:@"enableDetailedLabels"];
    self.enableTracks = [defaults boolForKey:@"enableTracks"];
    self.customURL = [defaults stringForKey:@"customURL"];
    self.filterSatellites = [defaults stringForKey:@"filterSatellites"];
    self.trackColor = [[NSColor alloc] initWithHex: [defaults stringForKey:@"trackColor"]];
    self.backgroundColor = [[NSColor alloc] initWithHex: [defaults stringForKey:@"backgroundColor"]];
    self.mapColor = [[NSColor alloc] initWithHex: [defaults stringForKey:@"mapColor"]];
    self.textColor = [[NSColor alloc] initWithHex: [defaults stringForKey:@"textColor"]];
}

-(void) loadDefaultsForEditing {
    NSString* appVersionString = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString* appBuildString = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString* appGitString = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"BundleGitVersion"];
    NSString* websiteLink = @"https://www.richinfante.com/2019/04/25/macos-satellite-screensaver-in-rust-swift-and-objc";
    
    [self.aboutLabel setStringValue: [NSString stringWithFormat:@"Version: %@\nBuild: %@\nTree: %@\n\nMore Info: %@", appVersionString, appBuildString, appGitString, websiteLink]];
    
    // Initialize elements to saved values.
    [self.enableTracksField setState: self.enableTracks ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.enableLabelBackgroundsField setState: self.enableLabelBackgrounds ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.enableDetailedLabelsField setState: self.enableDetailedLabels ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.customURLField setStringValue: self.customURL];
    [self.filterSatellitesField setStringValue: self.filterSatellites];
    [self.trackColorField setColor: self.trackColor];
    [self.mapColorField setColor: self.mapColor];
    [self.backgroundColorField setColor: self.backgroundColor];
    [self.textColorField setColor: self.textColor];
}

-(void) saveDefaults {
    // Reload defaults
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"SatelliteSaver"];
    [defaults setBool: self.enableDetailedLabels forKey:@"enableDetailedLabels"];
    [defaults setBool: self.enableLabelBackgrounds forKey:@"enableLabelBackgrounds"];
    [defaults setBool: self.enableTracks forKey:@"enableTracks"];
    [defaults setValue: self.customURL forKey:@"customURL"];
    [defaults setValue: self.filterSatellites forKey:@"filterSatellites"];
    [defaults setValue: [self.trackColor toHexString] forKey:@"trackColor"];
    [defaults setValue: [self.mapColor toHexString] forKey:@"mapColor"];
    [defaults setValue: [self.backgroundColor toHexString] forKey:@"backgroundColor"];
    [defaults setValue: [self.textColor toHexString] forKey:@"textColor"];
    [defaults synchronize];
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
        
        [[self mapColor] setStroke];
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
        
        [[self backgroundColor] setFill];
        [[self textColor] setStroke];
        NSBezierPath* outline = [NSBezierPath bezierPathWithRect:textBg];
        [outline stroke];
        NSRectFill(textBg);
    }
    
    // Draw satellite info.
    [formatted drawAtPoint:atPoint withAttributes: @{
        NSForegroundColorAttributeName: [self textColor],
        NSFontAttributeName: satelliteFont,
        NSParagraphStyleAttributeName: style
    }];
}

-(void)drawTrack:(TLE*) tle {
    NSRect gpscoord = NSMakeRect(-180.0, -90.0, 360.0, 180.0);
    
    // Define the screen coordinate space.
    NSRect bounds = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    
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
    [[tle trackColor] setStroke];
    [[tle trackColor] setFill];
    [control1 setLineWidth: 1];
    [control1 stroke];
}

- (void)drawRect:(NSRect)rect
{
    
//    NSArray* tles = [self.tleFetcher get_tlesFromURL:self.customURL filteringNames:self.filterSatellites];
    NSArray* tles = [self.tleFetcher get_tlesFromURL:self.customURL filteringNames:self.filterSatellites randomizingColors:NO defaultColor:self.trackColor];
    
    // For each loaded TLE, setup a new track.
    for (TLE* tle in tles) {
        const char* _Nullable  tle_str_lines = [tle.lines cStringUsingEncoding:NSASCIIStringEncoding];
        struct Track t = run_prediction((char*) tle_str_lines);
        [tle set_trackWithTrack:t];
    }
    
    // Fill background
    [[self backgroundColor] setFill];
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
    if (self.configSheet == nil)
    {
        NSArray *topLevelObjects;
        
        if (![[NSBundle bundleForClass:[self class]] loadNibNamed:@"ConfigureSheet" owner:self topLevelObjects:&topLevelObjects])
        {
            NSLog( @"Failed to load configure sheet." );
            NSBeep();
        }
    }
    
    [self loadDefaultsForEditing];
    return self.configSheet;
}

- (IBAction)configSheetCancelAction:(id)sender {
    [self loadDefaultsForEditing];

    if ([NSWindow respondsToSelector:@selector(endSheet:)])
    {
        [[self.configSheet sheetParent] endSheet:self.configSheet returnCode:NSModalResponseCancel];
    } else {
        [[NSApplication sharedApplication] endSheet:self.configSheet];
    }
}

- (IBAction)configSheetOKAction:(id)sender {

    // Load defaults into current view.
    self.enableDetailedLabels = [self.enableDetailedLabelsField state] == NSControlStateValueOn;
    self.enableLabelBackgrounds = [self.enableLabelBackgroundsField state] == NSControlStateValueOn;
    self.customURL = [self.customURLField stringValue];
    self.filterSatellites = [self.filterSatellitesField stringValue];
    self.enableTracks = [self.enableTracksField state] == NSControlStateValueOn;
    self.trackColor = [self.trackColorField color];
    self.mapColor = [self.mapColorField color];
    self.backgroundColor = [self.backgroundColorField color];
    self.textColor = [self.textColorField color];
    
    [self saveDefaults];
    
    // Issue refresh of TLEs.
    [self.tleFetcher reload];
    
    // Cancel the sheet.
    [self configSheetCancelAction:sender];
}

@end
