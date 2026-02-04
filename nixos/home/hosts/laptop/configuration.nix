{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # Import your hardware configuration file
  imports = [
    ./hardware-configuration.nix
    ../../../system/modules/boot.nix
    ../../../system/modules/hardware.nix
    ../../../system/modules/kde.nix
  ];

  nixpkgs = {
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      permittedInsecurePackages = [ "qtwebengine-5.15.19" ];
    };
  };

  # Define Nix settings (this should go under `config.nix`)
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath;
    };
    channel.enable = false;

    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Networking configuration goes under `config.networking`
  networking.hostName = "jgjoLaptop";
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.networkmanager.wifi.powersave = true;

  # onedrive
  services.onedrive.enable = true;

  # touchpad 
  services.libinput.enable = true;
  # multi-touch gesture recognizer
  services.touchegg.enable = true;

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  # User configuration goes under `config.users`
  users.users = {
    jgjo = {
      isNormalUser = true;
      shell = pkgs.zsh; # Use Zsh as login shell
      openssh.authorizedKeys.keys = [
        # Add your SSH public key(s) here
      ];
      extraGroups = ["wheel"];
    };
  };

  console.font = "Lat2-Terminus16";

  
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      jgjo = import ./home.nix;
    };
  };
  
  # SSH settings go under `config.services`
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # State version goes under `config.system`
  system.stateVersion = "23.05";


  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "da_DK.UTF-8";
    LC_IDENTIFICATION = "da_DK.UTF-8";
    LC_MEASUREMENT = "da_DK.UTF-8";
    LC_MONETARY = "da_DK.UTF-8";
    LC_NAME = "da_DK.UTF-8";
    LC_NUMERIC = "da_DK.UTF-8";
    LC_PAPER = "da_DK.UTF-8";
    LC_TELEPHONE = "da_DK.UTF-8";
    LC_TIME = "da_DK.UTF-8";
  };
  console.keyMap = "dk-latin1";

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

  # Enable Docker daemon
  virtualisation.docker.enable = true;

  # Enable VirtualBox
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "jgjo" ];

  # Enable Wireshark (allows non-root packet capture)
  programs.wireshark.enable = true;
  users.extraGroups.wireshark.members = [ "jgjo" ];

  # Enable Flatpak
  services.flatpak.enable = true;

  # Enable sound (kept here as general system configuration)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
