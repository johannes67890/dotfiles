#!/bin/bash

# Main setup script

# Source the color definitions and echo function
source "$(dirname "$0")/_setup/colors.sh"

# Define GitHub username and email
GITHUB_USERNAME="johannes67890"  # Replace with your GitHub username
GITHUB_EMAIL="johannes@orager.dk"  # Replace with your GitHub email

# Update and upgrade the system
tput sc # Save cursor position
colored_echo $BLUE "Updating and upgrading system..."
tput rc # Restore cursor position
sudo apt update && sudo apt upgrade -y

# Install necessary APT applications
tput sc # Save cursor position
colored_echo $BLUE "Installing APT-based applications..."
tput rc # Restore cursor position
bash _setup/install_apt.sh

# Download and install all .deb packages
tput sc # Save cursor position
colored_echo $BLUE "Installing .deb packages..."
tput rc # Restore cursor position
bash _setup/install_deb.sh

# Install Snap if not already installed
if ! command -v snap &> /dev/null; then
    colored_echo $YELLOW "Snap is not installed. Installing Snap..."
    sudo apt install snapd -y
else
    colored_echo $GREEN "Snap is already installed."
fi

# Install Snap packages
tput sc # Save cursor position
colored_echo $BLUE "Installing Snap-based applications..."
tput rc # Restore cursor position
bash _setup/install_snap.sh

# Backup or remove conflicting files, including .config/user settings
tput sc # Save cursor position
colored_echo $BLUE "Checking for file conflicts before stowing..."
tput rc # Restore cursor position
bash _setup/backup_conflicts.sh

# Stow dotfiles
tput sc # Save cursor position
colored_echo $BLUE "Stowing dotfiles..."
tput rc # Restore cursor position
bash _setup/stow_dotfiles.sh

# Configure global Git username and email
tput sc # Save cursor position
colored_echo $BLUE "Configuring global Git username and email..."
tput rc # Restore cursor position
git config --global user.name "$GITHUB_USERNAME"
git config --global user.email "$GITHUB_EMAIL"


# Set zsh as the default shell for the user
tput sc # Save cursor position
colored_echo $BLUE "Setting zsh as the default shell..."
tput rc # Restore cursor position
chsh -s $(which zsh)

colored_echo $GREEN "Setup complete! Please log out and back in for the changes to take effect."
