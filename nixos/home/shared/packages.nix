# Packages installed on every host.
#
# This module is wired into all home-manager configurations from flake.nix
# (see `sharedHomeModules`), so a new host gets this list for free.
#
# Host-specific packages still go in `home/hosts/<host>/home.nix`; home-manager
# merges `home.packages` across modules, so the two lists simply concatenate.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # --- System Utilities ---
    ghostty
    yazi
    lazygit
    lazydocker
    btop
    bat
    fastfetch
    wget
    curl
    whois
    jq
    tree
    zip
    unzip
    ripgrep
    fd          # used by telescope.nvim/neo-tree for fast file listing
    gnumake     # needed to build telescope-fzf-native.nvim's native sorter
    tree-sitter # CLI required by nvim-treesitter's `main` branch to build parsers
    patchelf
    appimage-run
    libnotify   # for plasma discovery application (with the use of flatpak)
    libglibutil
    ncurses.dev
    zlib
    icu
    sbctl       # secure boot key management (lanzaboote)
    terminus_font
    terminus_font_ttf

    # --- Bluetooth ---
    kdePackages.bluedevil
    kdePackages.bluez-qt

    # --- Shell Customization ---
    pure-prompt

    # --- Editors & AI tooling ---
    vscode
    claude-code
    opencode

    # --- GUI Apps ---
    firefox
    brave
    google-chrome
    tor-browser
    thunderbird
    discord
    signal-desktop
    spotify
    proton-vpn
    grimblast
    easyeffects
    krita

    # --- Office & Notes ---
    libreoffice
    obsidian
    affine
    outline
    calibre
    postman

    # --- Security & Privacy ---
    keepassxc
    gnupg
    veracrypt
    metadata-cleaner

    # --- System Management ---
    gparted
    flatpak
    qbittorrent
    jackett
    flaresolverr # main runs this as a service (services.flaresolverr.enable) too
    docker    # Note: Requires virtualisation.docker.enable = true in configuration.nix
    wireshark # Note: Requires programs.wireshark.enable = true in configuration.nix for permissions

    # --- Development Tools ---
    # C / C++
    gcc
    clang-tools
    cmake
    conan
    vcpkg
    cppcheck
    codespell
    doxygen
    gtest
    lcov

    # --- Languages & Runtimes ---
    # C#
    (dotnetCorePackages.combinePackages [
      dotnetCorePackages.sdk_10_0
      dotnetCorePackages.sdk_9_0
      dotnetCorePackages.sdk_8_0
    ])
    azure-functions-core-tools
    dotnet-ef

    # Rust
    # run 'rustup default stable' to install relevant rust packages
    rustup

    # Scala
    scala
    scala-cli
    metals  # Scala language server (Mason has no Scala LSP package)

    # Erlang
    erlang

    # Node
    nodejs
    pnpm
    yarn

    # Python
    python3

    # Java (uses also package 'gcc')
    jdk
    jdk21
    gradle
    maven

    # --- Cloud ---
    azure-cli

    # --- Latex / typesetting ---
    texlab
    tectonic
    typst
  ];
}
