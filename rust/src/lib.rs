extern crate satellite;
extern crate chrono;
use chrono::prelude::*;
use chrono::Duration;

use std::os::raw::*;
use std::ffi::{CString, CStr};

#[repr(C)]
#[derive(Copy, Clone)]
struct TrackPoint {
    pub latitude: f64,
    pub longitude: f64,
    pub altitude: f64
}

#[repr(C)]
struct Track {
    pub current: TrackPoint,
    pub track: [TrackPoint; 60]
}

#[no_mangle]
fn run_prediction(to: *const c_char) -> Track {
    let c_str = unsafe { CStr::from_ptr(to) };
    let tle = c_str.to_str().unwrap();

    let mut tles : Vec<String> = vec![ tle.into() ];

    let mut combined = String::new();
    for tle in tles {
        combined.push_str(&tle);
    }

    let (mut satrecs, errors) = satellite::io::parse_multiple(&combined);

    satrecs.reverse();

    for mut satrec in satrecs {
        let rec = satrec.clone();

        let time = Utc::now();
        let result = match satellite::propogation::propogate_datetime(&mut satrec, time) {
            Ok(result) => result,
            Err(e) => {
                println!("Failed to propgate: {:?}", e);
                continue
            }
        };

        // Perform calculations to find current position
        let gmst = satellite::propogation::gstime::gstime_datetime(time);
        let sat_pos = satellite::transforms::eci_to_geodedic(&result.position, gmst);

        // Store current position.
        let current_pos = TrackPoint {
            latitude: sat_pos.latitude * satellite::constants::RAD_TO_DEG,
            longitude: sat_pos.longitude * satellite::constants::RAD_TO_DEG,
            altitude: sat_pos.height
        };

        // Print hourly track.
        let track_duration : usize = 60;
        let mut tracks = [TrackPoint { latitude: 0.0, longitude: 0.0, altitude: 0.0 }; 60];
        let range = 0..track_duration;
        for i in range {
            
            // Compute the time
            let time = Utc::now() + Duration::minutes(((i as f64 - track_duration as f64 / 2.0) * 1.5) as i64);

            // Find position at the time
            let result = match satellite::propogation::propogate_datetime(&mut rec.clone(), time) {
                Ok(result) => result,
                Err(e) => {
                    println!("Failed to propgate track: {:?}", e);
                    continue
                    
                }
            };

            // Convert the position
            let gmst = satellite::propogation::gstime::gstime_datetime(time);
            let sat_pos = satellite::transforms::eci_to_geodedic(&result.position, gmst);

            // Save the point
            tracks[i] = TrackPoint {
                latitude: sat_pos.latitude * satellite::constants::RAD_TO_DEG,
                longitude: sat_pos.longitude * satellite::constants::RAD_TO_DEG,
                altitude: sat_pos.height
            };
        }

        return Track {
            current: current_pos,
            track: tracks
        }
    }

    unimplemented!()
}
