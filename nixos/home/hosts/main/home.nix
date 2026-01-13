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
    terminus_font
    terminus_font_ttf
    lazygit    
    wget
    curl
    btop
    git
    vim
    zsh
    vscode
    firefox
    grimblast
    google-chrome
    discord
    tor-browser
    vlc
    spotify
    obs-studio
    pure-prompt
    bat
    # zsh-you-should-use
    # stremio # Contain insecure package, qtwebengine-5.15.19
    libreoffice
    obsidian
    calibre
    krita
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
    oh-my-zsh
    docker
    virtualbox
    wireshark-qt
    postman
    neofetch
  ];

  fonts.fontconfig.enable = true;


  programs.home-manager.enable = true;
  programs.kitty.enable = true;
  programs.neovim.enable = true;
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
  programs.tmux.enable = true;

  programs.git = {
    enable = true;
settings.user.name = "johannes67890"; 
    settings.user.email = "johannes@orager.dk"; 

  };

}
