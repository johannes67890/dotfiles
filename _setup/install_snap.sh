#!/bin/bash

# install_snap.sh

# Source the color definitions and echo function
source "$(dirname "$0")/colors.sh"

# Define the list of snap packages to install
SNAP_APPS=(
  "spotify"
  "node --classic"
  "discord"
  "go --classic"
  "code --classic"
)

# Install Snap packages
for snap_app in "${SNAP_APPS[@]}"; do
    colored_echo $BLUE "Installing $snap_app with Snap..."
    if ! sudo snap install $snap_app; then
        colored_echo $RED "Error: Failed to install $snap_app."
    fi
done
