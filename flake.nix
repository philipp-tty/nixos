{
  description = "NixOS machines";

  inputs = {
    # Change this to the release you want to track.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, sops-nix, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.zeus = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          sops-nix.nixosModules.sops
          ./hosts/zeus/configuration.nix
        ];
      };
    };
}
