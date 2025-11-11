{ config, pkgs, ... }:

{
  home = {
    username = "jgjo";
    homeDirectory = "/home/jgjo";
    stateVersion = "24.11";
  };

  # Add user-level packages
  home.packages = with pkgs; [
    lazygit    
    wget
    curl
    btop
    git
    vim
    zsh

  ];


	programs.foot.settings.main.font = "Fira Code:size=11";


  programs.home-manager.enable = true;

  # Enable Neovim
  programs.neovim.enable = true;

  # Optional: Enable programs
  programs.zsh.enable = true;
  programs.tmux.enable = true;

  # Optional: Git configuration (if you want to customize it here)
programs.git = {
	enable = true;
	userName = "johannes67890";
	userEmail = "johannes@orager.dk";
};


  # Optional: Enable i3 window manager
  # xsession.windowManager.i3.enable = true;
}
