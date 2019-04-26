#include <stdint.h>

struct TrackPoint {
  double latitude;
  double longitude;
  double altitude;
};

struct Track {
  struct TrackPoint current;
  struct TrackPoint track[60];
};

struct Track run_prediction(char*);
