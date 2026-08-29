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
    jackett
    icu
		sbctl # for secure boot
    terminus_font
    terminus_font_ttf
    signal-desktop
    azure-cli
    flaresolverr
    whois
		lazygit   
		lazydocker
		wget
    curl
    btop
    bat
    opencode
    zip       
    unzip     
    tree
    ripgrep
    fd        # used by telescope.nvim/neo-tree for fast file listing
    gnumake   # needed to build telescope-fzf-native.nvim's native sorter
    libnotify # for plasma discovery application (with the use of flatpak)
    jq
    # --- Bluetooth --- 
    kdePackages.bluedevil
    kdePackages.bluez-qt    
		claude-code

    
    # --- GUI Apps ---
    vscode
    firefox
    grimblast
    google-chrome
    brave
    discord
    spotify
    thunderbird
    # ghidra
    proton-vpn
    # --- Shell Customization ---
    pure-prompt
    
    # --- Development Tools ---
    # C
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
    # C#
    (pkgs.dotnetCorePackages.combinePackages [
      pkgs.dotnetCorePackages.sdk_9_0
      pkgs.dotnetCorePackages.sdk_8_0
    ])
    azure-functions-core-tools
		dotnet-ef
    # Rust tools
		# run 'rustup default stable' to install relevant rust packages
		rustup

    # Node
    pnpm
    nodejs
    yarn

    # Python
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

    # Latex
    texlab
    tectonic

    # Office
    libreoffice
    krita
    postman
    fastfetch

    # --- System Management (See Warnings Below) ---
    # electrum
    gparted
    flatpak
    qbittorrent
    veracrypt
    gnupg
    docker       # Note: Requires virtualisation.docker.enable = true in configuration.nix
    wireshark    # Note: Requires programs.wireshark.enable = true in configuration.nix for permissions
    appimage-run
    keepassxc
    metadata-cleaner
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
  
  programs.kitty.enable = true;
  
  programs.neovim = {
    enable = true;
    defaultEditor = true; # Sets $EDITOR to nvim
    viAlias = true;       # Aliases vi to nvim
    vimAlias = true;      # Aliases vim to nvim
    sideloadInitLua = true;
    withRuby = false;
    withPython3 = false;
  };

  programs.tmux.enable = true;

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
