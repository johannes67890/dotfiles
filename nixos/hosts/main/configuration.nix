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
  ];

  config = {
  # Define nixpkgs options (place under config)
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
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

environment.systemPackages = [
pkgs.vscode
];
programs.hyprland = {
    enable = true;
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
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
  # Home Manager configurati
  # State version goes under `config.system`
  system.stateVersion = "23.05";

  # Bootloader configuration goes under `config.boot`
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # X server settings go under `config.services`
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  };
}
