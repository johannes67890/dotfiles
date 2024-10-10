#!/bin/bash

# install_zsh.sh

# Source the color definitions and echo function
source "$(dirname "$0")/colors.sh"

# Define Zsh plugins or themes URLs to install
ZSH_PLUGINS=(
  "https://github.com/zsh-users/zsh-autosuggestions"      # zsh-autosuggestions
  "https://github.com/zsh-users/zsh-syntax-highlighting"   # zsh-syntax-highlighting
  # Add more plugin/theme URLs as needed
)


    # Check if Zsh is installed
    if ! command -v zsh &> /dev/null; then
        colored_echo $BLUE "Installing Zsh..."
        if sudo apt-get install -y zsh; then
            colored_echo $GREEN "Zsh installed successfully."
        else
            colored_echo $RED "Error: Failed to install Zsh."
            exit 1  # Exit with error
        fi
    else
        colored_echo $GREEN "Zsh is already installed."
    fi

    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        colored_echo $BLUE "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        colored_echo $GREEN "Oh My Zsh installed successfully."
        colored_echo $YELLOW "You might need to re-run the script to install Zsh plugins."
    else
        colored_echo $GREEN "Oh My Zsh is already installed."
    fi

    # Initialize counter
    count=0
    total=${#ZSH_PLUGINS[@]}

    # Install Zsh plugins from URLs
    for plugin_url in "${ZSH_PLUGINS[@]}"; do
        plugin_name=$(basename "$plugin_url")
        plugin_dir="$HOME/.oh-my-zsh/custom/plugins/$plugin_name"

        if [ ! -d "$plugin_dir" ]; then
            colored_echo $BLUE "Installing $plugin_name..."
            if git clone "$plugin_url" "$plugin_dir"; then
                colored_echo $GREEN "$plugin_name installed successfully."
                ((count++))  # Increment counter on successful installation
            else
                colored_echo $RED "Error: Failed to install $plugin_name."
            fi
        else
            colored_echo $GREEN "$plugin_name is already installed."
            ((count++))  # Count already installed plugins
        fi
    done

    # Update .zshrc to enable the plugins
    if ! grep -q "zsh-autosuggestions" "$HOME/.zshrc"; then
        colored_echo $BLUE "Configuring .zshrc to enable plugins..."
        sed -i '/^plugins=(/ s/)/ zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
        colored_echo $GREEN "Plugins added to .zshrc."
    else
        colored_echo $GREEN "Plugins are already configured in .zshrc."
    fi

    colored_echo $BLUE "Reloading Zsh..."
    exec zsh  # Restart Zsh to apply changes

    # Summary of installations
    colored_echo $GREEN "Downloaded $count out of $total Zsh plugins successfully."