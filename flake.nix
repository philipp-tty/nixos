{
  description = "NixOS machines";

  inputs = {
    # Change this to the release you want to track.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.zeus = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/zeus/configuration.nix
        ];
      };
    };
}