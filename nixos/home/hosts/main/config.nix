{ config, pkgs, inputs, ... }:
let
  configDir = ../../config;
  avatarPath = "${configDir}/kde/avatar.jpg";
in
{
  imports = [
    "${configDir}/kde/plasma.nix"
  ];

  home.file = {
    # avatar for kde login and user account
    ".face" = {
      source = avatarPath;
    };
    ".face.icon" = {
      source = avatarPath;
    };

    # btop theme
    ".config/btop/themes/main.theme".source = "${configDir}/btop/main.theme";
    # Auto-select the "main" theme (matches main.theme filename)
    ".config/btop/btop.conf" = {
      text = ''
        # Managed by Home Manager
        color_theme = "main"
      '';
      force = true;
    };

    ".config/kde".source = "${configDir}/kde";
  };
}