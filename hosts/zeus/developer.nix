{ pkgs, lib, ... }:

let
  # Keep the host config resilient if a package name differs across nixpkgs revisions.
  optionalPkg = name: lib.optional (builtins.hasAttr name pkgs) (builtins.getAttr name pkgs);
in
{
  environment.systemPackages =
    (with pkgs; [
      # dev
      python3
      nodejs # includes `npm`/`npx`
      git
      gh
      micromamba
      codex
    ])
    # AI/dev assistants (best-effort; skipped if missing in the pinned nixpkgs)
    ++ optionalPkg "opencode"
    ++ optionalPkg "claude-code";
}

