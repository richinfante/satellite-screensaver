#include <stdint.h>
#include <stdbool.h>

// Bridge to Rust's TrackPoint
struct TrackPoint {
  double latitude;
  double longitude;
  double altitude;
};

// Bridge to Rust's Track
struct Track {
  bool error;
  struct TrackPoint current;
  struct TrackPoint track[60];
};

// prototype for rust's exposed run_prediction() function
struct Track run_prediction(char*);
