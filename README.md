# macOS Satellite Screensaver
This macOS Screensaver plots the position of satellites, by computing their position given orbital parameters. A mirror to access these is provided, but you may change it to use another source.

## Screenshot
![screenshot](img/large-satellite.jpg)

## How it Works
- TL;DR: Uses a combination of Rust, Swift, and Objective-C to display satellite locations. Prediction logic written in Rust, Swift/Objc used for macOS Screensaver portion.
- also, [see my blog post](https://www.richinfante.com/2019/04/25/macos-satellite-screensaver-in-rust-swift-and-objc)

## Credits
- World Map GeoJSON from [nvkelso/natural-earth-vector](https://github.com/nvkelso/natural-earth-vector/)
- TLEs mirrored to [celestrak.richinfante.com](https://celestrak.richinfante.com/stations.txt) from [celestrak.com](https://www.celestrak.com/NORAD/elements/stations.txt).