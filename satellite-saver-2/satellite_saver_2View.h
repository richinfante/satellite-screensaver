//
//  satellite_saver_2View.h
//  satellite-saver-2
//
//  Created by Rich Infante on 4/25/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import "Satellite-Swift.h"

@class GeoJSONCollection;
@class GeoJSONFeature;
@class GeoJSONGeometry;
@class GeoJSONFeature;
@class TLEFetcher;

@interface satellite_saver_2View : ScreenSaverView
@property (retain, nonatomic) TLEFetcher* tleFetcher;

@property (retain, nonatomic) NSString* customURL;
@property (retain, nonatomic) NSString* filterSatellites;
@property (nonatomic) BOOL enableDetailedLabels;
@property (nonatomic) BOOL enableLabelBackgrounds;
@property (nonatomic) BOOL enableTracks;

@property (strong) IBOutlet id configSheet;

@property (strong)  IBOutlet NSButton *enableDetailedLabelsField;
@property (strong)  IBOutlet NSButton *enableLabelBackgroundsField;
@property (strong)  IBOutlet NSButton *enableTracksField;
@property (strong)  IBOutlet NSTextField *customURLField;
@property (strong)  IBOutlet NSTextField *filterSatellitesField;


- (IBAction)configSheetCancelAction:(id)sender;
- (IBAction)configSheetOKAction:(id)sender;

@end
