#!/bin/bash

# install_deb.sh

# Source the color definitions and echo function
source "$(dirname "$0")/colors.sh"

# Define .deb package URLs
DEB_URLS=(
  https://launchpad.net/veracrypt/trunk/1.26.14/+download/veracrypt-console-1.26.14-Ubuntu-24.04-amd64.deb
  # Add more URLs as needed
)

# Function to download and install .deb packages
install_deb_from_url() {
  local url=$1
  local deb_file=$(basename "$url")

  colored_echo $BLUE "Downloading $deb_file from $url..."
  wget -q "$url" -O "$deb_file"

  colored_echo $BLUE "Making $deb_file executable..."
  chmod +x "$deb_file"

  colored_echo $BLUE "Installing $deb_file..."
  sudo dpkg -i "$deb_file"
  sudo apt-get install -f -y  # Fix any missing dependencies

  # Clean up the downloaded .deb file
  colored_echo $BLUE "Cleaning up $deb_file..."
  rm "$deb_file"
}

# Download and install all .deb packages
for url in "${DEB_URLS[@]}"; do
  install_deb_from_url "$url"
done
