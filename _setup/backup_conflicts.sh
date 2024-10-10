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

# Backup or remove conflicting files, including .config/user settings
backup_or_remove_conflicts() {
    for app in "${STOW_APPS[@]}"; do
        colored_echo $BLUE "Checking for conflicts in $app..."
        # List all files that would be linked by stow
        for file in $(stow -nv "$app" | grep -oP '(?<=\.\.\.\s).+'); do
            if [ -e "$HOME/$file" ]; then
                # If file exists, backup or remove
                colored_echo $YELLOW "Conflict found: $HOME/$file"
                if [ -f "$HOME/$file" ]; then
                    # Backup existing file
                    colored_echo $BLUE "Backing up $HOME/$file to $HOME/$file.backup"
                    mv "$HOME/$file" "$HOME/$file.backup"
                elif [ -d "$HOME/$file" ]; then
                    # Backup existing directory
                    colored_echo $BLUE "Backing up directory $HOME/$file to $HOME/$file.backup"
                    mv "$HOME/$file" "$HOME/$file.backup"
                fi
            fi
        done
    done
    
    # Remove old Ubuntu user settings in .config/user if they exist
    if [ -d "$HOME/.config/user" ]; then
        colored_echo $YELLOW "Removing old Ubuntu user settings in ~/.config/user..."
        rm -rf "$HOME/.config/user"
    fi
}

# Call the function to check for conflicts
backup_or_remove_conflicts
