#!/bin/bash

# Define the list of apt packages to install
APT_APPS=(
  git
  neovim
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
)

# Define the list of snap packages to install
SNAP_APPS=(
  spotify
  node
  discord
  vscode --classic
  # Add more Snap-based applications here
)

# Update and upgrade system
echo "Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

# Install the necessary APT applications
echo "Installing APT-based applications..."
for app in "${APT_APPS[@]}"; do
  echo "Installing $app with APT..."
  sudo apt install -y $app
done

# Install snap if not installed
if ! command -v snap &> /dev/null; then
  echo "Snap is not installed. Installing Snap..."
  sudo apt install snapd -y
else
  echo "Snap is already installed."
fi

# Install Snap packages
echo "Installing Snap-based applications..."
for snap_app in "${SNAP_APPS[@]}"; do
  echo "Installing $snap_app with Snap..."
  sudo snap install $snap_app
done

# Install GNU Stow if not already installed
if ! command -v stow &> /dev/null; then
  echo "GNU Stow is not installed. Installing it..."
  sudo apt install stow -y
else
  echo "GNU Stow is already installed."
fi

# Stow dotfiles
echo "Stowing dotfiles..."
cd ~/dotfiles

stow bash
stow neovim
stow git
stow alacritty
# Add more stow commands for other applications as needed

echo "Setup complete!"

