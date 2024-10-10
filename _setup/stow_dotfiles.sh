#!/bin/bash

# stow_dotfiles.sh

# Source the color definitions and echo function
source "$(dirname "$0")/colors.sh"

# Stow dotfiles
cd ~/dotfiles
for app in "${STOW_APPS[@]}"; do
    colored_echo $BLUE "Stowing $app..."
    stow "$app"
done
