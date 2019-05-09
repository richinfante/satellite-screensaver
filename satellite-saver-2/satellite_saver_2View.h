//
//  satellite_saver_2View.h
//  satellite-saver-2
//
//  Created by Rich Infante on 4/25/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>

@class GeoJSONCollection;
@class GeoJSONFeature;
@class GeoJSONGeometry;
@class GeoJSONFeature;
@class TLEFetcher;
@class DeploymentManifest;
@class GroundStationProvider;
@class DDFileLogger;
@protocol GroundStationProviderDelegate;

@interface satellite_saver_2View : ScreenSaverView <GroundStationProviderDelegate>

// Store TLEFetcher Instance
@property (retain, nonatomic) TLEFetcher* tleFetcher;
@property (retain, nonatomic) GroundStationProvider* groundStationProvider;

/// Settings
@property (retain, nonatomic) NSString* customURL;
@property (retain, nonatomic) NSString* filterSatellites;
@property (retain, nonatomic) NSColor* trackColor;
@property (retain, nonatomic) NSColor* mapColor;
@property (retain, nonatomic) NSColor* backgroundColor;
@property (retain, nonatomic) NSColor* textColor;
@property (nonatomic) BOOL enableLabels;
@property (nonatomic) BOOL enableDetailedLabels;
@property (nonatomic) BOOL enableLabelBackgrounds;
@property (nonatomic) BOOL enableTracks;
@property (nonatomic) BOOL enableStatusMessages;
@property (nonatomic) BOOL supressUpdateMessages;
@property (nonatomic) BOOL enableDynamicGroundStations;
@property (nonatomic) BOOL enableStaticGroundStations;
@property (retain, nonatomic) NSString* staticGroundStationJSON;
@property (retain, nonatomic) NSString* dynamicGroundStationURL;
@property (retain, nonatomic) NSString* manifestURL;

// Config seet outlets
@property (strong) IBOutlet id configSheet;
@property (strong) IBOutlet NSTextField* aboutLabel;
@property (strong) IBOutlet NSColorWell* trackColorField;
@property (strong) IBOutlet NSColorWell* mapColorField;
@property (strong) IBOutlet NSColorWell* backgroundColorField;
@property (strong) IBOutlet NSColorWell* textColorField;
@property (strong) IBOutlet NSButton* enableLabelsField;
@property (strong) IBOutlet NSButton* enableDetailedLabelsField;
@property (strong) IBOutlet NSButton* enableLabelBackgroundsField;
@property (strong) IBOutlet NSButton* enableTracksField;
@property (strong) IBOutlet NSButton* enableStatusMessagesField;
@property (strong) IBOutlet NSButton* supressUpdateMessagesField;
@property (strong) IBOutlet NSTextField* customURLField;
@property (strong) IBOutlet NSTextField* filterSatellitesField;

// Ground Station Config
@property (strong) IBOutlet NSTextField* dynamicGroundStationURLField;
@property (strong) IBOutlet NSTextView* staticGroundStationJSONField;
@property (strong) IBOutlet NSButton* enableDynamicGroundStationsField;
@property (strong) IBOutlet NSButton* enableStaticGroundStationsField;

// Debug Config

@property (strong) IBOutlet NSTextField* manifestURLField;

// Update checking
@property (strong) IBOutlet NSButton* updateAvailableButton;
@property (nonatomic) BOOL hasUpdates;
@property (retain, nonatomic) NSString* updateURL;
@property (retain, nonatomic) DeploymentManifest* deploymentManifest;
@property (retain, nonatomic) DDFileLogger* fileLogger;

/// Config sheet actions
- (IBAction)configSheetCancelAction:(id)sender;
- (IBAction)configSheetOKAction:(id)sender;
- (IBAction)configSheetOpenUpdateURL:(id)sender;
- (IBAction)didToggleGroundStationRadioButtons:(id)sender;
- (IBAction)openGithubProject:(id)sender;
- (IBAction)openDebugLogs:(id)sender;
@end
