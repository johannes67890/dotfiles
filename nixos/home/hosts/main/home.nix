{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./config.nix
  ];
  
  home = {
    username = "jgjo";
    homeDirectory = "/home/jgjo";
    stateVersion = "24.11";
  };

  # Add user-level packages
  home.packages = with pkgs; [
    # --- System Utilities ---
    terminus_font
    terminus_font_ttf
    lazygit    
    wget
    curl
    btop
    bat
    zip       
    unzip     
    tree
    ripgrep   
    jq        
    
    # --- GUI Apps ---
    vscode
    firefox
    grimblast
    google-chrome
    discord
    tor-browser
    vlc
    spotify
    obs-studio
    krita
    ghidra
    onedrive    
    protonvpn-gui
    # --- Shell Customization ---
    pure-prompt
    
    # --- Development Tools ---
    gcc
    clang-tools
    cmake
    codespell
    conan
    cppcheck
    doxygen
    gtest
    lcov
    vcpkg
    
    # --- Languages & Runtimes ---
    dotnet-sdk_8   # Added: You had dotnet-8 installed
    jdk21          # Added: You had Java 17/21 installed
    pnpm
    yarn           # Added: Found in your Snap list
    python3
    rustup
    go

    # --- Office & Productivity ---
    libreoffice
    obsidian
    calibre
    krita
    postman
    neofetch
    
    # --- System Management (See Warnings Below) ---
    gparted
    flatpak
    qbittorrent
    veracrypt
    gnupg
    pnpm
    nodejs
    python3
    rustup
    go
    docker       # Note: Requires virtualisation.docker.enable = true in configuration.nix
    virtualbox   # Note: Requires virtualisation.virtualbox.host.enable = true in configuration.nix
    wireshark-qt # Note: Requires programs.wireshark.enable = true in configuration.nix for permissions
  ];

  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;
  
  programs.kitty.enable = true;
  
  programs.neovim = {
    enable = true;
    defaultEditor = true; # Sets $EDITOR to nvim
    viAlias = true;       # Aliases vi to nvim
    vimAlias = true;      # Aliases vim to nvim
  };

  programs.tmux.enable = true;

  programs.zsh = {
    enable = true;

    plugins = [
      {
        name = "bat";
        src = pkgs.bat;
      }
    ];

    # Oh My Zsh
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "z" ];
    };

    initContent = ''
      # Pure prompt (sindresorhus/pure)
      fpath+=("${pkgs.pure-prompt}/share/zsh/site-functions")
      autoload -U promptinit; promptinit
      prompt pure
    '';

    # Plugins
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.git = {
    enable = true;
    settings.user.name = "johannes67890"; 
    settings.user.email = "johannes@orager.dk"; 
  };
}