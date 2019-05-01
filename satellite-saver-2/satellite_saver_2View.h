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

@interface satellite_saver_2View : ScreenSaverView

// Store TLEFetcher Instance
@property (retain, nonatomic) TLEFetcher* tleFetcher;

/// Settings
@property (retain, nonatomic) NSString* customURL;
@property (retain, nonatomic) NSString* filterSatellites;
@property (retain, nonatomic) NSColor* trackColor;
@property (retain, nonatomic) NSColor* mapColor;
@property (retain, nonatomic) NSColor* backgroundColor;
@property (retain, nonatomic) NSColor* textColor;
@property (nonatomic) BOOL enableDetailedLabels;
@property (nonatomic) BOOL enableLabelBackgrounds;
@property (nonatomic) BOOL enableTracks;
@property (nonatomic) BOOL enableStatusMessages;
@property (nonatomic) BOOL supressUpdateMessages;

// Config seet outlets
@property (strong) IBOutlet id configSheet;
@property (strong) IBOutlet NSTextField* aboutLabel;
@property (strong) IBOutlet NSColorWell* trackColorField;
@property (strong) IBOutlet NSColorWell* mapColorField;
@property (strong) IBOutlet NSColorWell* backgroundColorField;
@property (strong) IBOutlet NSColorWell* textColorField;
@property (strong) IBOutlet NSButton* enableDetailedLabelsField;
@property (strong) IBOutlet NSButton* enableLabelBackgroundsField;
@property (strong) IBOutlet NSButton* enableTracksField;
@property (strong) IBOutlet NSButton* enableStatusMessagesField;
@property (strong) IBOutlet NSButton* supressUpdateMessagesField;
@property (strong) IBOutlet NSTextField* customURLField;
@property (strong) IBOutlet NSTextField* filterSatellitesField;

// Update checking
@property (strong) IBOutlet NSButton* updateAvailableButton;
@property (nonatomic) BOOL hasUpdates;
@property (retain, nonatomic) NSString* updateURL;
@property (retain, nonatomic) DeploymentManifest* deploymentManifest;

/// Config sheet actions
- (IBAction)configSheetCancelAction:(id)sender;
- (IBAction)configSheetOKAction:(id)sender;
- (IBAction)configSheetOpenUpdateURL:(id)sender;
@end
