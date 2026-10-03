{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./config.nix
    ../../config/zsh/jetlink.nix
  ];
  
  home = {
    username = "jgjo";
    homeDirectory = "/home/jgjo";
    stateVersion = "25.11";
    sessionPath = [ "$HOME/.cargo/bin" ];
  };

  # Host-specific packages only.
  # The common list lives in home/shared/packages.nix and is applied to every
  # host from flake.nix; home-manager merges both lists together.
  home.packages = with pkgs; [
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
    sideloadInitLua = true;
    withRuby = false;
    withPython3 = false;
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
