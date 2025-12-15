# Building with Docker

## Quick Start

Build the firmware using Docker:

```bash
# Build left side (BT/USB)
./build-docker.sh

# Build right side (BT/USB)
SHIELD=charybdis_right ./build-docker.sh

# Build reset firmware
FORMAT=reset SHIELD=settings_reset ./build-docker.sh

# Build dongle configuration
FORMAT=dongle SHIELD=charybdis_left ./build-docker.sh
FORMAT=dongle SHIELD=charybdis_right ./build-docker.sh
FORMAT=dongle SHIELD=charybdis_dongle ./build-docker.sh
```

The firmware files will be in the `firmware/` directory.

## Configuration Options

**FORMAT** (default: `bt`)
- `bt` - Bluetooth/USB configuration
- `dongle` - Dongle configuration (better battery life on central)
- `reset` - Reset firmware

**SHIELD** (default: `charybdis_left`)
- `charybdis_left` - Left keyboard half
- `charybdis_right` - Right keyboard half (with ZMK Studio support)
- `charybdis_dongle` - Dongle (only for dongle format)
- `settings_reset` - Reset firmware (only for reset format)

## Custom Board

```bash
BOARD=nice_nano_v2 SHIELD=charybdis_left ./build-docker.sh
```

## What the Script Does

1. Pulls the official ZMK build Docker image
2. Initializes the west workspace from `config/west.yml`
3. Downloads all dependencies (ZMK, Zephyr, trackball drivers)
4. Builds the firmware for the specified board and shield
5. Copies the `.uf2` file to `firmware/` directory

## First Build

The first build will take several minutes as it downloads ~2GB of dependencies. Subsequent builds are much faster as dependencies are cached.

## Clean Build

```bash
rm -rf build .west modules zephyr zmk
./build-docker.sh
```
