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

@interface satellite_saver_2View : ScreenSaverView
@property (retain, nonatomic) TLEFetcher* tleFetcher;

@property (retain, nonatomic) NSString* customURL;
@property (retain, nonatomic) NSString* filterSatellites;
@property (retain, nonatomic) NSColor* trackColor;
@property (retain, nonatomic) NSColor* mapColor;
@property (retain, nonatomic) NSColor* backgroundColor;
@property (retain, nonatomic) NSColor* textColor;
@property (nonatomic) BOOL enableDetailedLabels;
@property (nonatomic) BOOL enableLabelBackgrounds;
@property (nonatomic) BOOL enableTracks;

@property (strong) IBOutlet id configSheet;
@property (strong) IBOutlet NSTextField* aboutLabel;

@property (strong) IBOutlet NSColorWell* trackColorField;
@property (strong) IBOutlet NSColorWell* mapColorField;
@property (strong) IBOutlet NSColorWell* backgroundColorField;
@property (strong) IBOutlet NSColorWell* textColorField;
@property (strong)  IBOutlet NSButton* enableDetailedLabelsField;
@property (strong)  IBOutlet NSButton* enableLabelBackgroundsField;
@property (strong)  IBOutlet NSButton* enableTracksField;
@property (strong)  IBOutlet NSTextField* customURLField;
@property (strong)  IBOutlet NSTextField* filterSatellitesField;

- (IBAction)configSheetCancelAction:(id)sender;
- (IBAction)configSheetOKAction:(id)sender;

@end
