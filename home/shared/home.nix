# User setup shared by every host (wired in via sharedHomeModules).
# Per-host bits (stateVersion, extra packages) stay in hosts/<host>/home.nix.
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./config.nix
    ../config/zsh/jetlink.nix
    ../config/spicetify/spicetify.nix
    ../config/vesktop/vesktop.nix
    ../config/zen/zen.nix
    ../config/quickshell/quickshell.nix
  ];
  
  home = {
    username = "jgjo";
    homeDirectory = "/home/jgjo";
    sessionPath = [ "$HOME/.cargo/bin" ];

    # Toolpack function apps against local Azurite; Ctrl-C stops all of them.
    packages = let
      # Shared start: Ctrl-C cleanup, port check, and Azurite unless it already runs.
      funcPreamble = ''
        set -euo pipefail
        fn=~/repos/Toolpack_Finance/AzureFunctions
        trap 'trap "" TERM; kill 0' EXIT  # kill children, keep our own exit code
        up() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }
        if ! up 10001; then
          azurite --silent --location ~/.local/share/azurite 2>&1 | sed -u 's/^/[azurite] /' &
          until up 10001; do sleep 0.5; done
        fi
      '';
    in [
      (pkgs.writeShellScriptBin "run-dbfunc" ''
        ${funcPreamble}
        app="$fn/ToolpackOne.Azure.dbFunctions"
        [ -f "$app/local.settings.json" ] || { echo "missing $app/local.settings.json"; exit 1; }

        # Azurite's well-known dev key; az rejects the UseDevelopmentStorage=true shortcut.
        conn="DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;"
        az_q() { az storage "$@" --only-show-errors --connection-string "$conn" -o none; }

        if [ $# -eq 1 ] && [ "$1" = --clear ]; then
          az_q queue create -n t1-db-queue
          az_q message clear -q t1-db-queue
          echo "Cleared t1-db-queue"; exit 0
        fi

        if [ $# -gt 0 ]; then
          if [ $# -eq 2 ] && [ "$1" = --migration ]; then
            body=$(printf '"Type":"UpgradeDatabase","CNumber":"%s"' "$2")
          elif [ $# -eq 4 ] && [ "$1" = --migration ] && [ "$2" = --down ]; then
            # Version = migration id to roll back to; Down() runs for every migration after it.
            body=$(printf '"Type":"DowngradeDatabase","CNumber":"%s","Version":"%s"' "$3" "$4")
          else
            echo "usage: run-dbfunc [--clear] [--migration <CNumber>] [--migration --down <CNumber> <Version>]"; exit 1
          fi
          token=$(az keyvault secret show --vault-name toolpackonevault-test --name PortalToken --query value -o tsv)
          # dbFunctions expects base64 messages, like the API sends.
          msg=$(printf '{%s,"Token":"%s"}' "$body" "$token" | base64 -w0)
          az_q queue create -n t1-db-queue
          az_q message put -q t1-db-queue --content "$msg"
          echo "Queued {$body}"
          if up 7073; then echo "dbFunctions is already running and will pick it up."; exit 0; fi
        fi

        cd "$app" && func start --port 7073
      '')
      (pkgs.writeShellScriptBin "run-func" ''
        ${funcPreamble}
        for app in jobManager integrationFunctions; do
          [ -f "$fn/ToolpackOne.Azure.$app/local.settings.json" ] || { echo "missing $fn/ToolpackOne.Azure.$app/local.settings.json"; exit 1; }
        done

        # jobManager first: it creates the queues.
        (cd "$fn/ToolpackOne.Azure.jobManager" && func start 2>&1 | sed -u 's/^/[jobManager] /') &
        jm=$!
        until up 7071; do kill -0 "$jm" 2>/dev/null || exit 1; sleep 2; done

        (cd "$fn/ToolpackOne.Azure.integrationFunctions" && func start --port 7072 2>&1 | sed -u 's/^/[integration] /') &
        wait
      '')
    ];
  };

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

  # Launcher replacing krunner (hotkeys in config/kde/plasma.nix).
  # rofi-calc uses qalc: math + currency ("100 usd to dkk"), rates refresh daily.
  programs.rofi = {
    enable = true;
    plugins = [ pkgs.rofi-calc ];
    theme = ../config/rofi/theme.rasi;
    settings = {
      modes = "drun,calc";
      terminal = "ghostty";
      font = "FiraCode Nerd Font 13";
      show-icons = true;
      drun-display-format = "{name}";
      matching = "fuzzy";
      sort = true;
      sorting-method = "fzf";
      click-to-exit = true;
      display-drun = "";
      display-calc = "";
    };
  };
  
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

  # Adds ls/ll/la/lt/lla aliases to zsh.
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
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

      # Anaconda (installed imperatively to ~/anaconda3)
      if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/anaconda3/etc/profile.d/conda.sh"
      fi
    '';

    # Plugins
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  # direnv: per-directory environments. Auto-hooks into zsh.
  # Used by ~/repos/IML2026/.envrc to activate the `iml` conda env
  # only inside that repo, instead of globally in every shell.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    settings.user.name = "johannes67890"; 
    settings.user.email = "johannes@orager.dk"; 
  };
}
