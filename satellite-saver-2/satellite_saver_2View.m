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

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        self.tleFetcher = [[TLEFetcher alloc] init];
        self.groundStationProvider = [[GroundStationProvider alloc] init];
        self.groundStationProvider.delegate = self;
        
        [self setAnimationTimeInterval:1.0];
        
        ScreenSaverDefaults *defaults;
        defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"SatelliteSaver"];
        
        // Register our default values
        [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                    @NO, @"enableLabelBackgrounds",
                                    @YES, @"enableDetailedLabels",
                                    @YES, @"enableTracks",
                                    @YES, @"enableStatusMessages",
                                    @NO, @"supressUpdateMessages",
                                    @YES, @"enableStaticGroundStations",
                                    @NO, @"enableDynamicGroundStations",
                                    @YES, @"enableLabels",
                                    @"https://public.richinfante.com/manifest/satellite-screensaver/manifest.json", @"manifestURL",
                                    @"https://public.richinfante.com/satellite-screensaver/spaceports.json", @"dynamicGroundStationURL",
                                    @"ISS (ZARYA)", @"filterSatellites",
                                    @"https://celestrak.richinfante.com/tdrss.txt", @"customURL",
                                    @"[]", @"staticGroundStationJSON",
                                    @"00ff00", @"trackColor",
                                    @"000000", @"backgroundColor",
                                    @"333333", @"mapColor",
                                    @"ffffff", @"textColor",
                                    nil]];
        
        
        if (@available(macOS 10.12, *)) {
            [DDLog addLogger:[DDOSLogger sharedInstance]];
        }
        
        DDFileLogger *fileLogger = [[DDFileLogger alloc] init]; // File Logger
        
        fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling

        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        [DDLog addLogger:fileLogger];
        
        self.fileLogger = fileLogger;
        
        DDLogInfo(@"Initializing Satellite Saver.");

        
        [self loadDefaults];
        
        // Set initial deploy config.
        self.hasUpdates = NO;
        self.deploymentManifest = nil;

        // BEGIN VERSION CHECKING -- delete if not needed.
        NSURL* manifestURL = [[NSURL alloc] initWithString: self.manifestURL];

        // Check for updates
        [DeploymentManifest initFromUrlWithUrl:manifestURL completion:^(DeploymentManifest* manifest){
            self.deploymentManifest = manifest;
            
            DDLogInfo(@"Needs Software Update: %d", [manifest needsUpdate]);

            // If update is needed, set info.
            if ([manifest needsUpdate]) {
                DDLogInfo(@"Update URL: %@", [manifest updateUrl]);
                DDLogInfo(@"Latest Build: %@", [manifest latestBuildString]);
                self.updateURL = [manifest updateUrl];
                self.hasUpdates = YES;
                [self.updateAvailableButton setHidden:NO];
            } else {
                self.hasUpdates = NO;
                [self.updateAvailableButton setHidden:YES];
            }
        }];
        // END VERSION CHECKING
    }
    return self;
}


/// Restore default settings
- (IBAction)restoreDefaults:(id)sender {
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"SatelliteSaver"];
    [defaults setBool:NO forKey:@"enableLabelBackgrounds"];
    [defaults setBool:YES forKey:@"enableDetailedLabels"];
    [defaults setBool:YES forKey:@"enableStatusMessages"];
    [defaults setBool:YES  forKey: @"enableTracks"];
    [defaults setBool:NO forKey:@"supressUpdateMessages"];
    [defaults setBool:YES forKey:@"enableStaticGroundStations"];
    [defaults setBool:NO forKey:@"enableDynamicGroundStations"];
    [defaults setBool:YES forKey:@"enableLabels"];
    [defaults setValue:@"https://public.richinfante.com/manifest/satellite-screensaver/manifest.json" forKey:@"manifestURL"];
    [defaults setValue:@"https://public.richinfante.com/satellite-screensaver/spaceports.json" forKey:@"dynamicGroundStationURL"];
    [defaults setValue:@"[]" forKey:@"staticGroundStationJSON"];
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

/// Load defaults from ScreensaverDefaults
-(void) loadDefaults {
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"SatelliteSaver"];
    self.enableLabelBackgrounds = [defaults boolForKey:@"enableLabelBackgrounds"];
    self.enableDetailedLabels = [defaults boolForKey:@"enableDetailedLabels"];
    self.enableTracks = [defaults boolForKey:@"enableTracks"];
    self.enableStatusMessages = [defaults boolForKey:@"enableStatusMessages"];
    self.supressUpdateMessages = [defaults boolForKey:@"supressUpdateMessages"];
    self.enableLabels = [defaults boolForKey:@"enableLabels"];
    self.enableDynamicGroundStations = [defaults boolForKey:@"enableDynamicGroundStations"];
    self.enableStaticGroundStations = [defaults boolForKey:@"enableStaticGroundStations"];
    self.manifestURL = [defaults stringForKey:@"manifestURL"];
    self.staticGroundStationJSON = [defaults stringForKey:@"staticGroundStationJSON"];
    self.dynamicGroundStationURL = [defaults stringForKey:@"dynamicGroundStationURL"];
    self.customURL = [defaults stringForKey:@"customURL"];
    self.filterSatellites = [defaults stringForKey:@"filterSatellites"];
    self.trackColor = [[NSColor alloc] initWithHex: [defaults stringForKey:@"trackColor"]];
    self.backgroundColor = [[NSColor alloc] initWithHex: [defaults stringForKey:@"backgroundColor"]];
    self.mapColor = [[NSColor alloc] initWithHex: [defaults stringForKey:@"mapColor"]];
    self.textColor = [[NSColor alloc] initWithHex: [defaults stringForKey:@"textColor"]];
}

/// Load information into config panel controls.
-(void) loadDefaultsForEditing {
    NSString* appVersionString = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString* appBuildString = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString* appGitString = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"BundleGitVersion"];
    NSString* websiteLink = @"https://www.richinfante.com/2019/04/25/macos-satellite-screensaver-in-rust-swift-and-objc";
    NSString* latestBuild = @"Unknown";
    NSString* updateURL = @"Unknown";
    
    // Try to fetch deployment info
    if (self.deploymentManifest) {
        latestBuild = [[self deploymentManifest] latestBuildString];
        updateURL = [[self deploymentManifest] updateUrl];
    }
    
    // Set about label
    [self.aboutLabel setStringValue: [NSString stringWithFormat:@"Version: %@\nBuild: %@\nTree: %@\n\nLatest Build: %@\nUpdate URL: %@\n\nMore Info: %@", appVersionString, appBuildString, appGitString, latestBuild, updateURL, websiteLink]];
    
    // Initialize elements to saved values.
    [self.updateAvailableButton setHidden:!self.hasUpdates];
    [self.enableTracksField setState: self.enableTracks ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.enableLabelBackgroundsField setState: self.enableLabelBackgrounds ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.enableDetailedLabelsField setState: self.enableDetailedLabels ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.enableStatusMessagesField setState: self.enableStatusMessages ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.supressUpdateMessagesField setState: self.supressUpdateMessages ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.enableStaticGroundStationsField setState: self.enableStaticGroundStations ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.enableDynamicGroundStationsField setState: self.enableDynamicGroundStations ? NSControlStateValueOn : NSControlStateValueOff ];
    [self.enableLabelsField setState: self.enableLabels ? NSControlStateValueOn : NSControlStateValueOff];
    [self.manifestURLField setStringValue: self.manifestURL];
    [self.staticGroundStationJSONField setString: self.staticGroundStationJSON];
    [self.dynamicGroundStationURLField setStringValue: self.dynamicGroundStationURL];
    [self.customURLField setStringValue: self.customURL];
    [self.filterSatellitesField setStringValue: self.filterSatellites];
    [self.trackColorField setColor: self.trackColor];
    [self.mapColorField setColor: self.mapColor];
    [self.backgroundColorField setColor: self.backgroundColor];
    [self.textColorField setColor: self.textColor];
}

/// Save currently loaded defaults.
-(void) saveDefaults {
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"SatelliteSaver"];
    [defaults setBool: self.enableDetailedLabels forKey:@"enableDetailedLabels"];
    [defaults setBool: self.enableLabelBackgrounds forKey:@"enableLabelBackgrounds"];
    [defaults setBool: self.enableTracks forKey:@"enableTracks"];
    [defaults setBool: self.enableStatusMessages forKey:@"enableStatusMessages"];
    [defaults setBool: self.supressUpdateMessages forKey:@"supressUpdateMessages"];
    [defaults setBool: self.enableStaticGroundStations forKey:@"enableStaticGroundStations"];
    [defaults setBool: self.enableDynamicGroundStations forKey:@"enableDynamicGroundStations"];
    [defaults setBool: self.enableLabels forKey:@"enableLabels"];
    [defaults setValue: self.manifestURL forKey:@"manifestURL"];
    [defaults setValue: self.staticGroundStationJSON forKey:@"staticGroundStationJSON"];
    [defaults setValue: self.dynamicGroundStationURL forKey:@"dynamicGroundStationURL"];
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

-(void)drawMarkerAtGPS:(NSPoint*) coords color:(NSColor*) color markerSize:(CGFloat)markerSize{
    NSRect gpscoord = NSMakeRect(-180.0, -90.0, 360.0, 180.0);
    NSRect bounds = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);

    [color setFill];
    
    NSPoint current_pos_screen = [self convertCoordinateSpace:coords fromSpace:&gpscoord toSpace: &bounds];
    NSRect marker_rect = NSMakeRect(current_pos_screen.x - markerSize, current_pos_screen.y - markerSize, markerSize * 2, markerSize * 2);
    NSRectFill(marker_rect);
}

-(void) drawMarkerText:(NSString*) text atGPS:(NSPoint*)coords markerSize:(CGFloat) markerSize fontSize:(float)fontSize{
    NSRect gpscoord = NSMakeRect(-180.0, -90.0, 360.0, 180.0);
    
    // Define the screen coordinate space.
    NSRect bounds = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    
    NSPoint current_pos_screen = [self convertCoordinateSpace:coords fromSpace:&gpscoord toSpace: &bounds];
    
    NSFont* satelliteFont = [NSFont fontWithName:@"Menlo" size:fontSize];
    
    NSSize size = [text sizeWithAttributes: @{
        NSFontAttributeName: satelliteFont
    }];
    

    
    
    // If it's too far to the right, switch to left aligned text.
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    CGFloat offset = markerSize * 4;
    if (current_pos_screen.x + markerSize * markerSize + size.width > self.bounds.origin.x + self.bounds.size.width) {
        style.alignment = NSTextAlignmentRight;
        offset = -offset + - size.width;
    }
    
    NSPoint atPoint = NSMakePoint(current_pos_screen.x + offset, current_pos_screen.y + markerSize / 2 - size.height / 2);
    
    if (self.enableLabelBackgrounds) {
        NSRect textBg = NSMakeRect(atPoint.x - 2, atPoint.y - 2, size.width + 4, size.height + 4);
        
        [[self backgroundColor] setFill];
        [[self textColor] setStroke];
        NSBezierPath* outline = [NSBezierPath bezierPathWithRect:textBg];
        [outline stroke];
        NSRectFill(textBg);
    }
    
    // Draw satellite info.
    [text drawAtPoint:atPoint withAttributes: @{
        NSForegroundColorAttributeName: [self textColor],
        NSFontAttributeName: satelliteFont,
        NSParagraphStyleAttributeName: style
    }];
}

-(void)drawMarker:(TLE*) tle {
    // Error processing? skip.
    if ([tle error]) {
        return;
    }

    struct TrackPoint current = [tle get_current_point];
    // Convert current pos.
    NSPoint current_pos = NSMakePoint(current.longitude, current.latitude);
    
    // Fill the marker rectangle.
    CGFloat boxRad = 5;
    if ([self isPreview]) {
        boxRad = 2.5;
    }
    
    [self drawMarkerAtGPS: &current_pos color: [tle trackColor] markerSize:boxRad];
}

-(void)drawMarkerText:(TLE*) tle {
    // Error processing? skip.
    if ([tle error]) {
        return;
    }

    struct TrackPoint current = [tle get_current_point];
    // Convert current pos.
    NSPoint current_pos = NSMakePoint(current.longitude, current.latitude);
    
    
    // Create a string for the current position info.
    NSString* formatted;
    
    if (!self.enableDetailedLabels) {
        formatted = [tle.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else {
        formatted = [NSString stringWithFormat: @"%@\nlat: %f°\nlng: %f°\nalt: %f km", tle.name, current.latitude, current.longitude, current.altitude];
    }
    
    // Fill the marker rectangle.
    CGFloat boxRad = 5;
    if ([self isPreview]) {
        boxRad = 2.5;
    }
    
    [self drawMarkerText:formatted atGPS:&current_pos markerSize:boxRad fontSize: 12];
}

-(void)drawTrack:(TLE*) tle {
    NSRect gpscoord = NSMakeRect(-180.0, -90.0, 360.0, 180.0);
    
    // Define the screen coordinate space.
    NSRect bounds = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    
    // Create a bezier path for the space track.
    NSBezierPath *control1 = [NSBezierPath bezierPath];
    
    // If no track available (due to error), or error with predictions, skip.
    if (![tle has_track] || [tle error]) {
        return;
    }
    
    struct Track t = [tle get_track];
    for (int i = 0; i < 59; i++) {
        
        // Convert p0 and p1 (consecutive points) to the coord space.
        NSPoint p0_init = NSMakePoint(t.track[i].longitude, t.track[i].latitude);
        NSPoint p0 = [self convertCoordinateSpace:&p0_init fromSpace:&gpscoord toSpace: &bounds];
        NSPoint p1_init = NSMakePoint(t.track[i+1].longitude, t.track[i+1].latitude);
        NSPoint p1 = [self convertCoordinateSpace:&p1_init fromSpace:&gpscoord toSpace: &bounds];
        [control1 moveToPoint:p0];
        
//        [control1 lineToPoint:p1];
//        p0 = 180
//        p1 = -180
        // If normal absvalue adjustment is less than width-adjusted,
        // HACK
        
        float xdist = fabs(p0.x - p1.x);
        float nxdist = fabs(xdist - 360);
        

        if (xdist < nxdist) {
            [control1 lineToPoint:p1];
        } else {
            [control1 moveToPoint:p1];
//            NSPoint p1_mida = NSMakePoint(p1.x, p1.y);
//            if (p1_mida.x < p0.x) {
//                p1_mida.x += self.bounds.size.width;
//            } else {
//                p1_mida.x -= self.bounds.size.width;
//            }
//
//            tle.name = [NSString stringWithFormat:@"%@\n mv: x:%f nx: %f", tle.name, xdist, nxdist];
//            [control1 lineToPoint:p1_mida];
//
//
//            if (i < 58) {
//                NSPoint p0_midb = NSMakePoint(p0.x, p0.y);
//
//                if (p0_midb.x < p1.x) {
//                    p0_midb.x -= self.bounds.size.width;
//                } else {
//                    p0_midb.x += self.bounds.size.width;
//                }
//
//
//                [control1 moveToPoint:p0_midb];
//                [control1 lineToPoint:p1];
//            }
        }
        
//        // If they're very far away, it's likely because it wraps the screen.
//        // To prevent the bezier curve making a line across, move instead of line.
//        if (fabs(p0.x - p1.x) < fabs(p0.x ) {
//            [control1 lineToPoint:p1];
//        } else {
//            NSPoint adjusted_point = NSMakePoint(p1_init.x, p1_init.y);
//            if (p0_init.x < 0 && p1_init.x > 0) {
//                adjusted_point.x += 360;
//            } else {
//                adjusted_point.x -= 360;
//            }
//
//            NSPoint p1m = [self convertCoordinateSpace:&adjusted_point fromSpace:&gpscoord toSpace: &bounds];
//
////             [control1 moveToPoint:p1];
//            [control1 lineToPoint:p1m];
//        }
        
    }
    
    // Fill the path.
    [[tle trackColor] setStroke];
    [[tle trackColor] setFill];
    [control1 setLineWidth: 1];
    [control1 stroke];
}

- (void)drawRect:(NSRect)rect
{
    NSArray* tles = [self.tleFetcher get_tlesFromURL:self.customURL filteringNames:self.filterSatellites randomizingColors:NO defaultColor:self.trackColor];
    
    // For each loaded TLE, setup a new track.
    for (TLE* tle in tles) {
        const char* _Nullable  tle_str_lines = [tle.lines cStringUsingEncoding:NSASCIIStringEncoding];
        @try {
            // *shouldn't* crash, but there's some situations where this may cause issues!
            struct Track t = run_prediction((char*) tle_str_lines);

            // Detect internal errors.
            if (t.error) {
                if (!tle.error) {
                    DDLogError(@"Error predicting for %@", tle.name);
                }
                tle.error = YES;
                continue;
            }

            // If all went well, copy the track into the tle object.
            [tle set_trackWithTrack:t];
        }
        @catch ( NSException *e ) {
            tle.error = YES;
            if (!tle.error) {
                DDLogError(@"Error Processing: %@: %@", [tle name], [e debugDescription]);
            }
        }
    }
    
    // Fill background
    [[self backgroundColor] setFill];
    NSRectFill(self.bounds);
    
    // Draw map
    [self drawMap];

    
    // Determine size + position for status messages.
    NSPoint infoPoint = NSMakePoint(100, 100);
    CGFloat infoSize = 12;
    if ([self isPreview]) {
        infoPoint = NSMakePoint(10, 10);
        infoSize = 8;
    }
    
    /// Show update available item
    if ([self hasUpdates] && ![self supressUpdateMessages]) {
        NSString* updatingString = @"Update Available! Visit Screensaver Config to Update.";
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *boldFont = [fontManager fontWithFamily:@"Menlo"
                                          traits:NSBoldFontMask
                                          weight:0
                                          size:infoSize];
        [updatingString drawAtPoint:infoPoint withAttributes:@{
           NSForegroundColorAttributeName: [self textColor],
           NSFontAttributeName: boldFont,
       }];
    } else if ([[self tleFetcher] is_fetching] && [self enableStatusMessages]) {
        // Show status information for orbital parameters.
        NSFont* satelliteFont = [NSFont fontWithName:@"Menlo" size:infoSize];
        NSString* updatingString = @"Fetching Orbital Parameters...";
        [updatingString drawAtPoint:infoPoint withAttributes:@{
           NSForegroundColorAttributeName: [self textColor],
           NSFontAttributeName: satelliteFont,
       }];
    } else if ([[self tleFetcher] fetch_error] && [self enableStatusMessages]) {
        // Show status information for orbital parameters.
        NSFont* satelliteFont = [NSFont fontWithName:@"Menlo" size:infoSize];
        NSString* updatingString = @"[!] Error Fetching Orbital Parameters.";
        [updatingString drawAtPoint:infoPoint withAttributes:@{
           NSForegroundColorAttributeName: [self textColor],
           NSFontAttributeName: satelliteFont,
       }];
    }
    
    NSArray* stations = [self.groundStationProvider getStations];
    
    // Draw ground stations if we have any.
    if (stations) {
        for (GroundStation* station in [stations reverseObjectEnumerator]) {
            NSPoint coords = [station getCoords];
            NSColor* color = [station getColorWithDefaultColor:self.trackColor];
            CGFloat boxRad = [station getPointSizeWithDefaultSize:5];
            
            if ([self isPreview]) {
                boxRad /= 2;
            }
            
            [self drawMarkerAtGPS:&coords color: color markerSize: boxRad];
        }
        
        if (![self isPreview] && self.enableLabels) {
            for (GroundStation* station in [stations reverseObjectEnumerator]) {
                if (station.title) {
                    NSPoint coords = [station getCoords];
                    // Fill the marker rectangle.
                    CGFloat boxRad = [station getPointSizeWithDefaultSize: 5];
                    float fontSize = [station getFontSizeWithDefaultSize:12];
                    if ([self isPreview]) {
                        boxRad /= 2;
                    }
                    
                    [self drawMarkerText:station.title atGPS:&coords markerSize:boxRad fontSize:fontSize];
                }
            }
        }
    }
    
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

    if (![self isPreview] && self.enableLabels) {
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
            DDLogError( @"Failed to load configure sheet." );
            NSBeep();
        }
    }
    
    [self loadDefaultsForEditing];
    [self didToggleGroundStationRadioButtons:nil];
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
    self.enableTracks = [self.enableTracksField state] == NSControlStateValueOn;
    self.enableStatusMessages = [self.enableStatusMessagesField state] == NSControlStateValueOn;
    self.supressUpdateMessages = [self.supressUpdateMessagesField state] == NSControlStateValueOn;
    self.enableStaticGroundStations = [self.enableStaticGroundStationsField state] == NSControlStateValueOn;
    self.enableDynamicGroundStations = [self.enableDynamicGroundStationsField state] == NSControlStateValueOn;
    self.enableLabels = [self.enableLabelsField state] == NSControlStateValueOn;
    self.manifestURL = [self.manifestURLField stringValue];
    self.staticGroundStationJSON = [self.staticGroundStationJSONField string];
    self.dynamicGroundStationURL = [self.dynamicGroundStationURLField stringValue];
    self.customURL = [self.customURLField stringValue];
    self.filterSatellites = [self.filterSatellitesField stringValue];
    self.trackColor = [self.trackColorField color];
    self.mapColor = [self.mapColorField color];
    self.backgroundColor = [self.backgroundColorField color];
    self.textColor = [self.textColorField color];
    
    [self saveDefaults];
    
    // Issue refresh of TLEs.
    [self.tleFetcher reload];
    
    [self.groundStationProvider purge];
    
    // Cancel the sheet.
    [self configSheetCancelAction:sender];
}

- (IBAction)configSheetOpenUpdateURL:(id)sender {
    if (self.updateURL != nil) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.updateURL]];
    }
}

- (IBAction)didToggleGroundStationRadioButtons:(id)sender {
    self.enableStaticGroundStations = [self.enableStaticGroundStationsField state] == NSControlStateValueOn;
    self.enableDynamicGroundStations = [self.enableDynamicGroundStationsField state] == NSControlStateValueOn;
    
    if (self.enableDynamicGroundStations) {
        [[self staticGroundStationJSONField] setEditable:NO];
        [[self dynamicGroundStationURLField] setEditable:YES];
    } else {
        [[self staticGroundStationJSONField] setEditable:YES];
        [[self dynamicGroundStationURLField] setEditable:NO];
    }
}

- (IBAction)openDebugLogs:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile: [[self.fileLogger currentLogFileInfo] filePath]];
}

-(IBAction)openGithubProject:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [[NSURL alloc] initWithString:@"https://github.com/richinfante/satellite-screensaver"]];
}


- (NSURL * _Nullable)getDynamicGroundStationsURL {
    return [[NSURL alloc] initWithString:self.dynamicGroundStationURL];
}

- (enum GroundStationMode)getGroundStationMode {
    if ([self enableStaticGroundStations]) {
        return GroundStationModeStaticJSON;
    } else if ([self enableDynamicGroundStations]) {
        return GroundStationModeDynamicURL;
    } else {
        return GroundStationModeDisabled;
    }
}

- (NSData * _Nullable)getStaticGroundStations {
    return [self.staticGroundStationJSON dataUsingEncoding:NSUTF8StringEncoding];
}
@end
