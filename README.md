# Dotfiles and Setup Script

This repository contains my dotfiles and a setup script to automate the installation of essential applications, set Zsh as the default shell, and link configuration files using GNU Stow.

## Features

- Installs essential APT, Snap, and Google Chrome applications.
- Configures **Zsh** as the default shell.
- Uses **GNU Stow** to manage dotfiles for apps like `git`, `nvim`, and `btop`.

## How to Use

### 1. Clone the repository:
```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## 2. Run the setup script:
```bash
./setup.sh
```

## 3. Restart your terminal.

## 4. Managing Dotfiles with Stow
The script uses GNU Stow to link configuration files. You can add more apps by placing their config files in ~/dotfiles/<app> and running:
```bash
stow <app>
```