#!/bin/bash

# install_apt.sh

# Source the color definitions and echo function
source "$(dirname "$0")/colors.sh"

# Define APT packages to install
APT_APPS=(
  git
  neovim
  go
  ulauncher
  curl
  pandoc
  npm
  nodejs
  btop
  python3-pip
  flatpak
  docker
  pipx
  dotnet
  veracrypt
  tree
  wget
  zsh
)

for app in "${APT_APPS[@]}"; do
    colored_echo $BLUE "Installing $app with APT..."
    if ! sudo apt install -y "$app"; then
        colored_echo $RED "Error: Failed to install $app."
    fi
done