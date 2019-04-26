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
@property (retain, nonatomic) NSString* fetchURL;
@property (nonatomic) BOOL shortNameMode;
@property (nonatomic) BOOL enableTextBackground;
@end
