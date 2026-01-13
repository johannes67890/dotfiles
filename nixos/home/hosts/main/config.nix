{ config, pkgs, inputs, ... }:
let
  configDir = ../../config;
in
{
  imports = [
    "${configDir}/kde/plasma.nix"
  ];

  home.file = {
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