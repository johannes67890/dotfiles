{ config, pkgs, inputs, ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  
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
  
  programs.home-manager.enable = true;
  programs.kitty.enable = true;
  programs.neovim.enable = true;
  programs.zsh.enable = true;
  programs.tmux.enable = true;

  programs.git = {
    enable = true;
    userName = "johannes67890";
    userEmail = "johannes@orager.dk";
  };

  # Add Hyprland configuration via home-manager, sourcing external files
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = let
      hyprDir = ../../config/hypr;
      files = [
        "hyprland.conf"
        "monitor.conf"
        "input.conf"
        "bind.conf"
        "exec.conf"
        "window.conf"
        "windowrule.conf"
        "hyprpaper.conf"
      ];
      readOrEmpty = name: builtins.readFile "${hyprDir}/${name}";
    in builtins.concatStringsSep "\n\n" (map readOrEmpty files);
  };

  # Keep waybar configuration (files managed under home/config/waybar)
  programs.waybar = {
    enable = true;
    systemd = {
      enable = false;
      target = "graphical-session.target";
    };
  };

  # Install Waybar config files
  xdg.configFile."waybar/config.jsonc".source = ../../config/waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ../../config/waybar/style.css;
}
