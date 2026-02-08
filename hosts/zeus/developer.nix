{
  pkgs,
  lib,
  ...
}: let
  npmGlobalPrefix = "/var/lib/npm-global";

  # Keep the host config resilient if a package name differs across nixpkgs revisions.
  pkgByNames = names: let
    name = lib.findFirst (n: builtins.hasAttr n pkgs) null names;
  in
    if name == null
    then throw "Expected one of these packages to exist in pkgs: ${lib.concatStringsSep ", " names}"
    else builtins.getAttr name pkgs;
in {
  # Required for running some prebuilt (non-Nix) Linux binaries downloaded by tools like npm.
  # Example: `opencode-ai` ships a dynamically linked executable.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      glibc
      stdenv.cc.cc
    ];
  };

  environment.systemPackages = with pkgs; [
    # dev
    python3
    nodejs # includes `npm`/`npx`
    git
    gh
    micromamba
    efibootmgr

    # developer CLI staples
    ripgrep # rg
    ugrep
    (pkgByNames ["ast-grep"]) # sg
    (pkgByNames ["fd" "fd-find"])
    jq
    (pkgByNames ["yq-go" "yq"]) # yq
    (pkgByNames ["miller"]) # mlr
    csvkit # csvcut/csvstat/...
    bat
    (pkgByNames ["delta" "git-delta"])
    fzf
  ];

  # Install agent CLIs via npm global installs instead of nixpkgs packages.
  #
  # Why:
  # - these tools update frequently (npm is a better fit than nixpkgs pinning)
  # - nixpkgs packages sometimes lag behind upstream
  #
  # Trade-off:
  # - not fully reproducible; requires network access at install time.
  systemd.tmpfiles.rules = [
    "d ${npmGlobalPrefix} 0755 root root -"
    "d ${npmGlobalPrefix}/bin 0755 root root -"
    "d /var/cache/npm 0755 root root -"
    "d /var/lib/npm 0755 root root -"
  ];

  # Make npm global installs usable in interactive shells.
  environment.extraInit = ''
    export NPM_CONFIG_PREFIX="${npmGlobalPrefix}"
    export PATH="$PATH:${npmGlobalPrefix}/bin"
  '';

  systemd.services.npm-global-agent-clis = {
    description = "Ensure Codex/OpenCode/Claude Code CLIs are installed via npm";
    after = ["network-online.target"];
    wants = ["network-online.target"];

    # `npm` may spawn `sh` for lifecycle scripts; provide a shell + a few basics in PATH.
    path = with pkgs; [
      bash
      nodejs
      git
      python3
    ];

    # Run via timer to avoid blocking `nixos-rebuild switch` if npm is temporarily unhappy.
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "30min";
      Environment = [
        "HOME=/var/lib/npm"
        "NPM_CONFIG_PREFIX=${npmGlobalPrefix}"
        "NPM_CONFIG_CACHE=/var/cache/npm"
        "NPM_CONFIG_UPDATE_NOTIFIER=false"
        "SHELL=${pkgs.bash}/bin/bash"
        "npm_config_script_shell=${pkgs.bash}/bin/bash"
      ];

      ExecStart = pkgs.writeShellScript "npm-global-agent-clis" ''
        set -euo pipefail

        mkdir -p "$NPM_CONFIG_PREFIX" "$NPM_CONFIG_CACHE"

        # If any tool is missing, (re)install them.
        if [ ! -x "$NPM_CONFIG_PREFIX/bin/codex" ] || [ ! -x "$NPM_CONFIG_PREFIX/bin/opencode" ] || [ ! -x "$NPM_CONFIG_PREFIX/bin/claude" ]; then
          ${pkgs.nodejs}/bin/npm install -g \
            --unsafe-perm=true \
            --no-fund \
            --no-audit \
            --prefix "$NPM_CONFIG_PREFIX" \
            @openai/codex \
            opencode-ai \
            @anthropic-ai/claude-code
        fi
      '';
    };
  };

  systemd.timers.npm-global-agent-clis = {
    description = "Ensure Codex/OpenCode/Claude Code CLIs are installed via npm (timer)";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1d";
      Persistent = true;
      Unit = "npm-global-agent-clis.service";
    };
  };
}
