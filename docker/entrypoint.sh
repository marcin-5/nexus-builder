#!/bin/bash
set -e

FISH_CONFIG_DIR="/root/.config/fish"
DEFAULT_CONFIG_DIR="/opt/fish_config_default"
APP_NAME=${APP_NAME:-nexus-builder}
RUST_DIR=${RUST_DIR:-rust}
TZ=${TZ:-UTC}

echo "Starting $APP_NAME..."

# Set timezone at runtime
if [ "$TZ" != "UTC" ]; then
    echo "Setting timezone to $TZ"
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
fi

# Make sure the app and rust directories exist
mkdir -p /app
mkdir -p /app/${RUST_DIR}

# If the config directory is mounted but uninitialized (i.e., fisher is missing),
# copy the default config from the image into the volume.
if [ ! -f "$FISH_CONFIG_DIR/functions/fisher.fish" ]; then
   echo "Initializing fish config in $FISH_CONFIG_DIR..."
   # Ensure the target functions directory exists before copying
   mkdir -p "$FISH_CONFIG_DIR/functions"

   # Check if default config exists before copying
   if [ -d "$DEFAULT_CONFIG_DIR" ] && [ "$(ls -A $DEFAULT_CONFIG_DIR)" ]; then
      cp -a "$DEFAULT_CONFIG_DIR/." "$FISH_CONFIG_DIR/"
   else
      echo "Warning: Default fish configuration not found in $DEFAULT_CONFIG_DIR"
      # Create a minimal fish config if the default one doesn't exist
      echo "# Basic fish configuration" > "$FISH_CONFIG_DIR/config.fish"
   fi
fi

# Check if we should run commands in the rust directory
if [ -d "/app/${RUST_DIR}" ] && [ -f "/app/${RUST_DIR}/Cargo.toml" ]; then
   cd /app/${RUST_DIR}
   echo "Working in Rust directory: /app/${RUST_DIR}"
else
   cd /app
   echo "Working in app directory: /app"
fi

# Execute the command passed to the container
exec "$@"
