# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # Pinned ahead of nixpkgs (4.8.0) for .NET 10 isolated worker support.
  azure-functions-core-tools = pkgs.callPackage ./azure-functions-core-tools/package.nix { };
}
