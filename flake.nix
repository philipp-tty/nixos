{
  description = "NixOS machines";

  inputs = {
    # Change this to the release you want to track.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    sops-nix,
    home-manager,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (nixpkgs) lib;
    src = lib.cleanSourceWith {
      src = ./.;
      filter = path: type: let
        name = baseNameOf path;
      in
        lib.cleanSourceFilter path type
        && name != "result"
        && !(lib.hasPrefix "result-" name)
        && name != ".direnv";
    };
    mkZeus = extraModules:
      lib.nixosSystem {
        inherit system;
        modules =
          [
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                # Avoid Home Manager failing when legacy/manual dotfiles exist.
                # Conflicting files get renamed to `*.hm-bak` on activation.
                backupFileExtension = "hm-bak";
                users.philipp = import ./hosts/zeus/home.nix;
              };
            }
          ]
          ++ extraModules;
      };
  in {
    formatter.${system} = pkgs.alejandra;

    checks.${system} = {
      alejandra = pkgs.runCommand "alejandra-check" {nativeBuildInputs = [pkgs.alejandra];} ''
        alejandra --check ${src}
        touch $out
      '';

      statix = pkgs.runCommand "statix-check" {nativeBuildInputs = [pkgs.statix];} ''
        export HOME="$TMPDIR"
        export XDG_CACHE_HOME="$TMPDIR"
        statix check ${src}
        touch $out
      '';

      deadnix = pkgs.runCommand "deadnix-check" {nativeBuildInputs = [pkgs.deadnix];} ''
        deadnix --fail ${src}
        touch $out
      '';
    };

    nixosConfigurations.zeus = mkZeus [
      ./hosts/zeus/configuration.nix
    ];

    nixosConfigurations.zeus-ci = mkZeus [
      ./hosts/zeus/base.nix
      ./hosts/zeus/ci-hardware.nix
    ];
  };
}
