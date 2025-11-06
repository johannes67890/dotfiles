{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    }
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      extraSpecialArgs = { inherit inputs; };
      modules = [ 
        ./configuration.nix
        inputs.home-manager.nixosModules.default
       ];
    };
  };
}
