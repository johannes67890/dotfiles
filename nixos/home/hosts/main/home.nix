{ config, pkgs, inputs, ... }:

{
  imports = [
    ./config.nix
  ];
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
    google-chrome
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
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
  };
  programs.tmux.enable = true;

  programs.git = {
    enable = true;
settings.user.name = "johannes67890"; 
    settings.user.email = "johannes@orager.dk"; 

  };

}
