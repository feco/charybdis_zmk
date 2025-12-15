# Dockerfile for building ZMK firmware locally
# Based on the official ZMK build container
FROM zmkfirmware/zmk-build-arm:stable

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies for keymap conversion
RUN pip3 install --no-cache-dir remarshal

# Set working directory
WORKDIR /workspace

# The build will be run by mounting the current directory to /workspace
# and executing the build commands
