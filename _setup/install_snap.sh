#!/bin/bash

# install_snap.sh

# Source the color definitions and echo function
source "$(dirname "$0")/colors.sh"

# Define the list of snap packages to install
SNAP_APPS=(
  spotify
  node
  discord
  go --classic
  vscode --classic
)

# Install Snap packages
for snap_app in "${SNAP_APPS[@]}"; do
    colored_echo $BLUE "Installing $snap_app with Snap..."
    sudo snap install "$snap_app"
done
