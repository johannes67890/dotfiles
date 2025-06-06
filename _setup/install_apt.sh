#!/bin/bash

# install_apt.sh

# Source the color definitions and echo function
source "$(dirname "$0")/colors.sh"

# Define APT packages to install
APT_APPS=(
  git
  libreoffice
  neovim
  ulauncher
  curl
  pandoc
  npm
  nodejs
  btop
  onedriver
  wmctrl # Needed for ulauncher
  python3-pip
  flatpak
  pipx
  lazygit
  lazydocker
  tree
  wget
  zsh
  texlive-science texlive-latex-extra texlive-extra-utils latexmk texlive-publishers texlive-science # Latex
)

# Initialize counter
count=0
total=${#APT_APPS[@]}

# Install necessary APT applications
for app in "${APT_APPS[@]}"; do
    colored_echo $BLUE "Installing $app with APT..."
    if sudo apt-get install -y "$app"; then
        colored_echo $GREEN "Installed $app."
        ((count++))  # Increment counter on successful installation
    else
        colored_echo $RED "Error: Failed to install $app."
    fi
done

# Output the count
colored_echo $GREEN "$count/$total APT packages downloaded."
