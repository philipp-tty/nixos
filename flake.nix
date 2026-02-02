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
    in
    {
      nixosConfigurations.zeus = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/zeus/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.philipp = import ./hosts/zeus/home.nix;
          }
        ];
      };
    };
}
