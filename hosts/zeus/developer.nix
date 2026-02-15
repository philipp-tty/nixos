{
  pkgs,
  pkgsUnstable,
  pkgsLlmAgents,
  lib,
  ...
}: let
  prismaEngines = pkgs.prisma-engines;

  # Keep the host config resilient if a package name differs across nixpkgs revisions.
  pkgByNamesFrom = packageSet: names: let
    name = lib.findFirst (n: builtins.hasAttr n packageSet) null names;
  in
    if name == null
    then throw "Expected one of these packages to exist in pkgs: ${lib.concatStringsSep ", " names}"
    else builtins.getAttr name packageSet;

  pkgByNames = pkgByNamesFrom pkgs;
  unstablePkgByNames = pkgByNamesFrom pkgsUnstable;
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
    pnpm
    openssl
    texliveFull
    prisma-engines
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

    # Agent CLIs from numtide/llm-agents.nix (daily builds, latest versions).
    pkgsLlmAgents.codex
    pkgsLlmAgents.opencode
    pkgsLlmAgents.claude-code
  ];

  # Prisma on NixOS: force CLI/runtime to use Nix-provided engines so it does
  # not attempt to fetch `linux-nixos` artifacts that are often unavailable.
  environment.variables = {
    PRISMA_QUERY_ENGINE_LIBRARY = "${prismaEngines}/lib/libquery_engine.node";
    PRISMA_QUERY_ENGINE_BINARY = "${prismaEngines}/bin/query-engine";
    PRISMA_SCHEMA_ENGINE_BINARY = "${prismaEngines}/bin/schema-engine";
    PRISMA_FMT_BINARY = "${prismaEngines}/bin/prisma-fmt";
    PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING = "1";
  };
}
