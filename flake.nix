{
  description = "NixOS machines";

  inputs = {
    # Change this to the release you want to track.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      mkZeus = extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.philipp = import ./hosts/zeus/home.nix;
          }
        ] ++ extraModules;
      };
    in
    {
      nixosConfigurations.zeus = mkZeus [
        ./hosts/zeus/configuration.nix
      ];

      nixosConfigurations.zeus-ci = mkZeus [
        ./hosts/zeus/base.nix
        ./hosts/zeus/ci-hardware.nix
      ];

      nixosConfigurations.zeus-installer = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/zeus/installer.nix
        ];
      };

      packages.${system}.zeus-installer-iso =
        self.nixosConfigurations.zeus-installer.config.system.build.isoImage;
    };
}
