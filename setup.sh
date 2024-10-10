#!/bin/bash

# Define the list of apt packages to install
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

# Define the list of snap packages to install
SNAP_APPS=(
  spotify
  node
  discord
  go --classic
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

# Install Google Chrome
echo "Installing Google Chrome..."
wget -q -O google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome.deb
sudo apt-get install -f -y  # Install dependencies if needed
rm google-chrome.deb  # Clean up

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

# Set zsh as the default shell for the user
echo "Setting zsh as the default shell..."
chsh -s $(which zsh)

# Stow dotfiles
echo "Stowing dotfiles..."
cd ~/dotfiles

stow bash
stow neovim
stow git
stow alacritty
# Add more stow commands for other applications as needed

echo "Setup complete!"

