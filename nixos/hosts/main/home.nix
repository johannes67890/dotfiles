{ config, pkgs, ... }:

{

 nixpkgs = {
    # You can add overlays here
      # Add overlays your own flake exports (from overlays and pkgs dir):

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
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
    lazygit    
    wget
    curl
    btop
    git
    vim
    zsh
    vscode
  ];




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
