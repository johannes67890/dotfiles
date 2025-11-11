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
    inputs.hyprland.nixosModules.default
    inputs.home-manager.nixosModules.home-manager  # Add this line
  ];

  nixpkgs = {
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
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
  };

  # Networking configuration goes under `config.networking`
  networking.hostName = "jgjo";

  # User configuration goes under `config.users`
  users.users = {
    jgjo = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        # Add your SSH public key(s) here
      ];
      extraGroups = ["wheel"];
    };
  };

  console.font = "Lat2-Terminus16";

  # Enable XDG portal for proper Wayland integration - Fix the configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;  # Add this for Hyprland
    extraPortals = with pkgs; [ 
      xdg-desktop-portal-gtk 
    ];
    config.common.default = "*";  # Add this line
  };
  
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "jgjo" = import ./home.nix;
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

  # Bootloader configuration goes under `config.boot`
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;

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

  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = false;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

  # X server settings go under `config.services`
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
  # Enable Wayland support in GDM
  services.xserver.displayManager.gdm.wayland = true;
  
  # Add Hyprland configuration with basic settings
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # Keep the essential packages for Hyprland
  environment.systemPackages = with pkgs; [
    waybar           # Status bar
    wofi             # Application launcher  
    dunst            # Notifications
    grim             # Screenshot utility
    slurp            # Screen area selection
    wl-clipboard     # Clipboard utilities
  ];
  
  # Set default session to Hyprland
  services.displayManager.defaultSession = "hyprland";

  # Enable sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
