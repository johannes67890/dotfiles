{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./config.nix
  ];
  
  home = {
    username = "jgjo";
    homeDirectory = "/home/jgjo";
    stateVersion = "25.11";
    sessionPath = [ "$HOME/.cargo/bin" ];
  };

  # Add user-level packages
  home.packages = with pkgs; [
    # --- System Utilities ---
    ghostty
    yazi
    terminus_font
    terminus_font_ttf
    lazygit    
    azure-cli
    wget
    curl
    opencode
    btop
    bat
    zip       
    unzip     
    tree
    ripgrep   
    jq
    libnotify # for plasma discovery application (with the use of flatpak)
    # --- Bluetooth --- 
    kdePackages.bluedevil
    kdePackages.bluez-qt    
    
    # --- GUI Apps ---
    vscode
    firefox
    chromium
    grimblast
    brave
    discord
    tor-browser
    vlc
    bitwarden-desktop
    spotify
    obs-studio
    thunderbird
    ghidra
    onedrive    
    proton-vpn
    # --- Shell Customization ---
    pure-prompt
   android-studio 
    # --- Development Tools ---
    # C
    gcc
    clang-tools
    cmake
    codespell
    conan
    google-chrome
		easyeffects
		cppcheck
    doxygen
    gtest
    lcov
    vcpkg
    
    # --- Languages & Runtimes ---
    # C#
    dotnet-sdk_9   # Added: You had dotnet-8 installed
    # Rust tools
    rustup

    # Node
    pnpm
    nodejs
    yarn

    # Python
    pipx
    python3

    # Java (uses also package 'gcc')
    jdk21          # Added: You had Java 17/21 installed
    gradle
    jdk
    maven
    ncurses.dev
    patchelf
    zlib

    # go
    go

    # Latex
    (pkgs.texlive.combine {
      inherit (pkgs.texlive) scheme-full
        latexmk
        wrapfig amsmath ulem hyperref capt-of
        xifthen ifmtarg framed paralist titlesec;
    })
    texlab
    tectonic

    # Office
    libreoffice
    obsidian
    calibre
    krita
    postman
    fastfetch
    rclone

    # --- System Management (See Warnings Below) ---
    # electrum
    gparted
    flatpak
    qbittorrent
    veracrypt
    gnupg
    docker       # Note: Requires virtualisation.docker.enable = true in configuration.nix
    virtualbox   # Note: Requires virtualisation.virtualbox.host.enable = true in configuration.nix
    wireshark    # Note: Requires programs.wireshark.enable = true in configuration.nix for permissions
    onionshare
    appimage-run
    keepassxc
    metadata-cleaner
    oh-my-zsh
    libglibutil
  ];

  fonts.fontconfig.enable = true;

  xdg.desktopEntries."com.mitchellh.ghostty" = {
    name = "Ghostty";
    genericName = "Terminal";
    exec = "env GTK_IM_MODULE=simple ghostty";
    terminal = false;
    type = "Application";
    categories = [ "System" "TerminalEmulator" ];
    icon = "com.mitchellh.ghostty";
    startupNotify = true;
  };

  programs.home-manager.enable = true;
  
  
  programs.neovim = {
    enable = true;
    defaultEditor = true; # Sets $EDITOR to nvim
    viAlias = true;       # Aliases vi to nvim
    vimAlias = true;      # Aliases vim to nvim
  };


  programs.zsh = {
    enable = true;

		shellAliases = {
      toolpack = "cd ~/repos/Toolpack_Finance/";
      run-api = ''cd ~/repos/Toolpack_Finance/backend/Api && ASPNETCORE_ENVIRONMENT=Development dotnet watch run --project ToolpackFinance.Api.csproj --urls "http://localhost:8080;https://localhost:5001"'';
      run-api-debug = ''cd ~/repos/Toolpack_Finance/backend/Api && ASPNETCORE_ENVIRONMENT=Development dotnet watch run --project ToolpackFinance.Api.csproj --urls "http://localhost:8080;https://localhost:5001" --configuration Debug'';
      run-web = "cd ~/repos/Toolpack_Finance/web && pnpm run dev";
      run-web-debug = "cd ~/repos/Toolpack_Finance/web && pnpm run dev --debug";
    };

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
