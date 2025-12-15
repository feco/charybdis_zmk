#!/bin/bash
# Simple Docker build script for ZMK Charybdis firmware

set -e

BOARD="${BOARD:-nice_nano_v2}"
SHIELD="${SHIELD:-charybdis_left}"
FORMAT="${FORMAT:-bt}"
BUILD_DIR="build"
OUTPUT_DIR="firmware"

echo "Building ZMK firmware..."
echo "Board: $BOARD"
echo "Shield: $SHIELD"
echo "Format: $FORMAT"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Backup original keymap and restore on exit
KEYMAP_BACKUP=""
cleanup() {
  if [ -n "$KEYMAP_BACKUP" ] && [ -f "$KEYMAP_BACKUP" ]; then
    echo "Restoring original keymap..."
    mv "$KEYMAP_BACKUP" config/charybdis.keymap
  fi
}
trap cleanup EXIT

# Remove other format shields so only the target format is found
echo "Preparing shield directories..."
find boards/shields -mindepth 1 -maxdepth 1 -type d ! -name "charybdis-${FORMAT}" -exec rm -rf {} + 2>/dev/null || true

# Copy physical layout file to the shield directory
if [ -f "config/charybdis-layouts.dtsi" ] && [ -d "boards/shields/charybdis-${FORMAT}" ]; then
  echo "Copying physical layout file..."
  cp config/charybdis-layouts.dtsi "boards/shields/charybdis-${FORMAT}/"
fi

# For BT format, convert trackball device reference
if [[ "$FORMAT" == "bt" ]] && [ -f "config/charybdis.keymap" ]; then
  echo "Converting trackball reference for BT format..."
  KEYMAP_BACKUP="config/charybdis.keymap.backup"
  cp config/charybdis.keymap "$KEYMAP_BACKUP"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/device = <&vtrackball>;/device = <\&trackball>;/g' config/charybdis.keymap
  else
    sed -i 's/device = <&vtrackball>;/device = <\&trackball>;/g' config/charybdis.keymap
  fi
fi

# Run build in Docker
# Build in container's /tmp to avoid conflicts with zephyr/module.yml
docker run --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  zmkfirmware/zmk-build-arm:stable \
  bash -c "
    set -e

    # Check if this is an extra module (zephyr/module.yml exists)
    if [ -e zephyr/module.yml ]; then
      echo 'Detected zephyr/module.yml - building as extra module'
      BUILD_BASE_DIR=\"/tmp/zmk-build\"
      ZMK_EXTRA_MODULES=\"-DZMK_EXTRA_MODULES=/workspace\"
    else
      BUILD_BASE_DIR=\"/workspace\"
      ZMK_EXTRA_MODULES=\"\"
    fi

    # Create base directory if needed
    mkdir -p \"\$BUILD_BASE_DIR/config\"

    # Copy config files to build directory
    if [ \"\$BUILD_BASE_DIR\" != \"/workspace\" ]; then
      cp -R /workspace/config/* \"\$BUILD_BASE_DIR/config/\"
    fi

    # Initialize west workspace if not already done
    if [ ! -d \"\$BUILD_BASE_DIR/.west\" ]; then
      echo 'Initializing west workspace...'
      cd \"\$BUILD_BASE_DIR\"
      west init -l config
    else
      echo 'West workspace already initialized'
      cd \"\$BUILD_BASE_DIR\"
    fi

    echo 'Updating dependencies...'
    west update

    echo 'Exporting Zephyr environment...'
    west zephyr-export

    echo 'Building firmware...'
    west build --pristine -s zmk/app -d $BUILD_DIR -b $BOARD -- \
      -DSHIELD=$SHIELD \
      -DZMK_CONFIG=\$BUILD_BASE_DIR/config \
      -DBOARD_ROOT=/workspace \
      \$ZMK_EXTRA_MODULES

    # Copy firmware back to workspace
    if [ -f \"$BUILD_DIR/zephyr/zmk.uf2\" ]; then
      cp \"$BUILD_DIR/zephyr/zmk.uf2\" \"/workspace/$OUTPUT_DIR/${SHIELD}.uf2\"
    fi
  "

# Check if firmware was created
if [ -f "$OUTPUT_DIR/${SHIELD}.uf2" ]; then
  echo ""
  echo "✓ Build successful!"
  echo "Firmware: $OUTPUT_DIR/${SHIELD}.uf2"
else
  echo "✗ Build failed - no firmware file generated"
  exit 1
fi
