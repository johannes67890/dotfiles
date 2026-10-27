{
  lib,
  pkgs,
  ...
}: {
  # Same machine as hosts/surface, headless: no KDE, no home-manager desktop
  # packages. Switch an existing surface install with
  # `nixos-rebuild switch --flake .#surface-server`.
  imports = [
    ../surface/hardware-configuration.nix
    ../../../system/config.nix
    ../../../system/modules/boot.nix
    ../../../system/modules/hardware-non-nvidia.nix
  ];

  networking.hostName = "surface-server";

  # Dual boot with Windows 11 (shares this ESP). Register NixOS in the firmware
  # boot menu, and keep the RTC in local time like Windows does. Boot Windows
  # once from SSH: `sudo systemctl reboot --boot-loader-entry=auto-windows`.
  boot.loader.efi.canTouchEfiVariables = true;
  time.hardwareClockInLocalTime = true;

  # Stay up with the lid shut, never suspend.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
  systemd.targets = lib.genAttrs ["sleep" "suspend" "hibernate" "hybrid-sleep"] (_: {enable = false;});

  # Desktop-only bits from system/config.nix.
  services.flatpak.enable = lib.mkForce false;

  # Idle power: blank the console after 60s, runtime-PM for devices.
  # ponytail: powertop autotune also autosuspends USB; if a USB disk/NIC drops
  # out, drop this line or exempt the device.
  boot.kernelParams = ["consoleblank=60"];
  powerManagement.powertop.enable = true;

  services.thermald.enable = true;
  services.fwupd.enable = true;

  # Media + share root. Jellyfin reads it (world-readable), jgjo writes it.
  systemd.tmpfiles.rules = ["d /srv/share 0755 jgjo users -"];

  # Web UI on :8096; point libraries at /srv/share/media.
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # NAS: \\surface-server\share. Set the SMB password once: `sudo smbpasswd -a jgjo`.
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "server string" = "surface-server";
        "map to guest" = "never";
      };
      share = {
        path = "/srv/share";
        "read only" = "no";
        "valid users" = "jgjo";
        "force user" = "jgjo";
      };
    };
  };

  # Private network. Join once with `sudo tailscale up`; then reach this box as
  # surface-server from any device on the tailnet.
  services.tailscale = {
    enable = true;
    openFirewall = true; # direct peer connections instead of relays
  };

  environment.systemPackages = with pkgs; [git neovim btop efibootmgr];

  users.users.jgjo.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuhSgtnu/KlLpBzh3cLznt/0+KeWBPlnJ4al7Oz+sA+ johannes@orager.dk" # from fw host list
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+o4pH1zmrXpEaUIP9fY0mbCyegLI0j5rR/v62AeiwT johannes@orager.dk" # desktop (main)
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINPZ/LKt2V0JEb06a34/ktDMWXF3p6+ENQp2uqBnlNc0 johannes@orager.dk"
  ];

  system.stateVersion = "23.05";
}
