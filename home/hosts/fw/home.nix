{ pkgs, ... }:
{
  home.stateVersion = "26.05";

  # Host-specific packages only; the common list is in home/shared/packages.nix.
  home.packages = with pkgs; [
    # --- JetBrains ---
    jetbrains.idea
    jetbrains.gateway
  ];
}
