{ inputs, lib, pkgs, config, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  config = {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;

      # Use Hyprland from the flake input
      package = inputs.hyprland.packages.${system}.hyprland;
      portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
    };

    # Make Hyprland the default session while keeping GNOME selectable in GDM
    services.displayManager.defaultSession = lib.mkDefault "hyprland";

    # Portals
    xdg.portal = {
      enable = lib.mkDefault true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland
      ];
    };

    # Common tools for a usable session
    environment.systemPackages = with pkgs; [
      waybar
      wofi
      dunst
      wl-clipboard
      grim
      slurp
      kitty
    ];

    # NVIDIA-friendly vars
    environment.sessionVariables = lib.mkIf (
      (config.hardware ? nvidia) && ((config.hardware.nvidia.modesetting.enable or false))
    ) {
      WLR_NO_HARDWARE_CURSORS = "1";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      NVD_BACKEND = "direct";
    };
  };
}