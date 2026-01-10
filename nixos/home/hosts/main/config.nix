{ config, pkgs, inputs, ... }:
let
  configDir = ../../config;
in
{
  imports = [
    ../../config/kde/plasma.nix
  ];

  home.file.".config/kde".source = "${configDir}/kde";
}