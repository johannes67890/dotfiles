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
    ".config/btop/btop.conf" = {
      text = ''
        # Managed by Home Manager
        color_theme = "main"
      '';
      force = true;
    };

    # nvim config
    ".config/nvim".source = "${configDir}/nvim/.config/nvim";

    ".config/kde".source = "${configDir}/kde";
    
    # ghostty config
    ".config/ghostty/config".source = "${configDir}/ghostty/config";
    ".config/ghostty/config".force = true;

    # yazi config
    ".config/yazi".source = "${configDir}/yazi";

    # opencode config
    ".config/opencode/agent/core/ask.md" = {
      source = "${configDir}/opencode/agent/core/ask.md";
      force = true;
    };
  };
}
