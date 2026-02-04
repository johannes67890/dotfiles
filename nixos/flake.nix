{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # for secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    plasma-manager,
    lanzaboote,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "x86_64-linux"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    # Your custom packages and modifications,ration entrypoint
    # Available through 'nixos-rebuild --flake .#jgjo'
    nixosConfigurations = {
      jgjo = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        
        modules = [
          # > Our main nixos configuration file <
          ./home/hosts/main/configuration.nix
          # > Home manager <
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ];
          }

          lanzaboote.nixosModules.lanzaboote        
        ];
      };
      laptop = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs outputs;};
          modules = [
            ./home/hosts/laptop/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [
                inputs.plasma-manager.homeModules.plasma-manager
              ];
            }
            lanzaboote.nixosModules.lanzaboote
          ];
  };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#jgjo@jgjo'
    homeConfigurations = {
      "jgjo@jgjo" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
        modules = [
          inputs.plasma-manager.homeModules.plasma-manager
          ./home/hosts/main/home.nix
        ];
      };

       "jgjo@laptop" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            inputs.plasma-manager.homeModules.plasma-manager
            ./home/hosts/laptop/home.nix
          ];
        };
    };
  };
}
