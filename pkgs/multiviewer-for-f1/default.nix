{
  alsa-lib,
  at-spi2-atk,
  autoPatchelfHook,
  cairo,
  cups,
  dbus,
  dpkg,
  expat,
  ffmpeg,
  fetchurl,
  glib,
  gtk3,
  lib,
  libdrm,
  libgbm,
  libudev0-shim,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  makeWrapper,
  nspr,
  nss,
  pango,
  stdenvNoCC,
  writeScript,
}: let
  id = "367699519";
in
  stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "multiviewer-for-f1";
    version = "2.6.0";

    src = fetchurl {
      url = "https://releases.multiviewer.app/download/${id}/multiviewer_${finalAttrs.version}_amd64.deb";
      hash = "sha256-tlDrPA1drM/rNtiXb1GZPzxkCwYi3I9Gkvr3tJ9YzcI=";
    };

    nativeBuildInputs = [
      dpkg
      makeWrapper
      autoPatchelfHook
    ];

    buildInputs = [
      alsa-lib
      at-spi2-atk
      cairo
      cups
      dbus
      expat
      ffmpeg
      glib
      gtk3
      libdrm
      libxkbcommon
      libgbm
      nspr
      nss
      pango
      libx11
      libxcomposite
      libxcb
      libxdamage
      libxext
      libxfixes
      libxrandr
    ];

    dontBuild = true;
    dontConfigure = true;

    unpackPhase = ''
      runHook preUnpack

      # The deb file contains a setuid binary, so 'dpkg -x' doesn't work here.
      dpkg --fsys-tarfile "$src" | tar --extract

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/share"
      mv -t "$out/share" usr/share/* usr/lib/multiviewer

      wayland_flags="''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform=wayland --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

      makeWrapper "$out/share/multiviewer/multiviewer" "$out/bin/multiviewer" \
        --add-flags "$wayland_flags" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [libudev0-shim]}:\"$out/share/multiviewer\""

      runHook postInstall
    '';

    passthru.updateScript = writeScript "update-multiviewer-for-f1" ''
      #!/usr/bin/env nix-shell
      #!nix-shell -i bash -p curl jq common-updater-scripts
      set -eu -o pipefail

      latest=$(curl -s "https://api.multiviewer.app/api/v1/releases/latest/")

      link=$(echo "$latest" | jq -r '.downloads[] | select(.platform=="linux_deb").url')
      id=$(echo "$latest" | jq -r '.downloads[] | select(.platform=="linux_deb").id')
      version=$(echo "$latest" | jq -r '.version')

      if [ "$version" != "${finalAttrs.version}" ]; then
        hash=$(nix-hash --type sha256 --to-sri "$(nix-prefetch-url --type sha256 "$link")")

        sed -i "s/id = \"[0-9]*\"/id = \"$id\"/" ${__curPos.file}
        update-source-version ${finalAttrs.pname} "$version" "$hash" --system=x86_64-linux
      fi
    '';

    meta = {
      description = "Unofficial desktop client for F1 TV";
      homepage = "https://multiviewer.app";
      downloadPage = "https://multiviewer.app/download";
      license = lib.licenses.unfree;
      maintainers = with lib.maintainers; [
        babeuh
        philipp-tty
      ];
      platforms = ["x86_64-linux"];
      mainProgram = "multiviewer";
    };
  })
