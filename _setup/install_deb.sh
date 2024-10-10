#!/bin/bash

# install_deb.sh

# Source the color definitions and echo function
source "$(dirname "$0")/colors.sh"

# Define .deb package URLs
DEB_URLS=(
 https://launchpad.net/veracrypt/trunk/1.26.14/+download/veracrypt-1.26.14-Ubuntu-24.04-amd64.deb
)

# Initialize counter
count=0
total=${#DEB_URLS[@]}

# Function to download and install .deb packages
install_deb_from_url() {
  local url=$1
  local deb_file=$(basename "$url")

  colored_echo $BLUE "Downloading $deb_file from $url..."
  if wget -q "$url" -O "$deb_file"; then
      colored_echo $BLUE "Making $deb_file executable..."
      chmod +x "$deb_file"

      colored_echo $BLUE "Installing $deb_file..."
      if sudo dpkg -i "$deb_file"; then
          ((count++))  # Increment counter on successful installation
      else
          colored_echo $RED "Error: Failed to install $deb_file. Fixing dependencies..."
          sudo apt-get install -f -y  # Attempt to fix any missing dependencies
          if [ $? -ne 0 ]; then
              colored_echo $RED "Error: Could not fix dependencies for $deb_file."
          fi
      fi

      # Clean up the downloaded .deb file
      colored_echo $GREEN "Installed $deb_file, Cleaning up ..."
      rm "$deb_file"
  else
      colored_echo $RED "Error: Failed to download $deb_file. Please check the URL."
  fi
}

# Download and install all .deb packages
for url in "${DEB_URLS[@]}"; do
  install_deb_from_url "$url"
done

# Output the count
colored_echo $GREEN "$count/$total .deb packages downloaded."
