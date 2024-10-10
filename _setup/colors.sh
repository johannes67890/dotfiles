#!/bin/bash

# colors.sh

# Define color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

# Function for colored echo
colored_echo() {
    local color="$1"
    shift
    echo -e "${color}$*${RESET}"
}
