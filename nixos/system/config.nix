{ inputs, lib, config, ... }:
{
  # Shared overlays (common to all hosts).
  nixpkgs.overlays = [
    (final: prev: {
      # nixpkgs ships 4.8.0, whose host targets net8.0 and cannot load the
      # Microsoft.Extensions.* 10.x assemblies a .NET 10 isolated worker app
      # binds against. 4.15.1 targets net10.0. See pkgs/azure-functions-core-tools.
      azure-functions-core-tools =
        final.callPackage ../pkgs/azure-functions-core-tools/package.nix { };
    })
  ];

  # Shared Nix settings (common to all hosts).
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      flake-registry = "";
      # Point <nixpkgs> & friends at the flake inputs. nix.nixPath is now a
      # rename of this option, so reading it here would be self-referential.
      nix-path = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };
    channel.enable = false;

    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
