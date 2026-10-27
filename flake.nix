{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # azure-cli is unbuildable on nixos-unstable: it needs fabric, and nixpkgs
    # marks fabric broken whenever invoke >= 3 (fabric upstream doesn't support
    # invoke 3.x -- https://github.com/fabric/fabric/issues/2376). Forcing it
    # through produces a fabric that fails 20 of its own tests with
    # "ConnectionCall.make_context() got an unexpected keyword argument", so
    # it's a real incompatibility, not a packaging nit.
    #
    # 25.11 still ships invoke 2.2.0, where fabric is supported and unbroken,
    # so azure-cli is pulled from there (see the overlay in system/config.nix).
    # Being a release channel it comes from the binary cache. Revisit once
    # fabric gains invoke 3.x support upstream.
    nixpkgs-azure.url = "github:nixos/nixpkgs/nixos-25.11";

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

    # Hardware quirks (Framework etc.)
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # for secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";

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

    # Home-manager modules applied to every host. Add anything that should be
    # present on all machines here; host-specific bits stay in
    # ./home/hosts/<host>/home.nix.
    sharedHomeModules = [
      inputs.plasma-manager.homeModules.plasma-manager
      ./home/shared/home.nix
      ./home/shared/packages.nix
    ];
  in {
    # Formatter for your nix files, available through 'nix fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # One system per host; available through 'nixos-rebuild --flake .#<host>'.
    # Home-manager runs as part of each system, so there is no standalone setup.
    nixosConfigurations = nixpkgs.lib.mapAttrs (_: hostDir:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./home/hosts/${hostDir}/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = sharedHomeModules;
          }
          lanzaboote.nixosModules.lanzaboote
        ];
      }) {
      jgjo = "main"; # desktop
      surface = "surface";
      surface-server = "surface-server";
      fw = "fw";
    };
  };
}
