#!/bin/bash

# backup_conflicts.sh

# Source the color definitions and echo function
source "$(dirname "$0")/colors.sh"

# Define directories that will be stowed
STOW_APPS=(
  bash
  git
  nvim
  btop
  zsh
)

    # Remove old Ubuntu user settings in .config/user if they exist
    if [ -d "$HOME/.config/user" ]; then
        colored_echo $YELLOW "Removing old Ubuntu user settings in ~/.config/user..."
        rm -rf "$HOME/.config/user"
    fi

