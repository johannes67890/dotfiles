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
    stremio # Contain insecure package, qtwebengine-5.15.19
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
    # kde plasma widgets
    kdePackages.kdeplasma-addons   # contains org.kde.plasma.weather, colorpicker, …
    kdePackages.plasma-nm          # network management tray
    plasma-panel-colorizer
    kdePackages.kweather           # optional: KWeather app
  ];

  fonts.fontconfig.enable = true;
  
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "Terminus";
          style = "Regular";
        };
        size = 12;
      };
    };
  };
  

  home.activation.pagerOpacity = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -e
    src=/run/current-system/sw/share/plasma/plasmoids/org.kde.plasma.pager
    dst=$HOME/.local/share/plasma/plasmoids/org.kde.plasma.pager

    rm -rf "$dst"
    cp -r "$src" "$dst"

    # Lower selection highlight opacity in QML. This injects "opacity: 0.35"
    # right after lines using the selection/highlight color.
    for f in "$dst"/contents/ui/*.qml; do
      if grep -q 'highlightColor' "$f"; then
        awk '{
          print
          if ($0 ~ /highlightColor/ && injected == 0) {
            print "    opacity: 0.35"
            injected = 1
          }
        }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
      fi
    done
  '';

  programs.home-manager.enable = true;
  programs.kitty.enable = true;
  programs.neovim.enable = true;
  programs.zsh = {
    enable = true;

    # Oh My Zsh
    oh-my-zsh = {
      enable = true;
      theme = "agnoster"; # or "powerlevel10k/powerlevel10k"
      plugins = [ "git" "sudo" "z" ];
    };

    # Nice extras
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
