{
  fetchzip,
  jre,
  lib,
  makeDesktopItem,
  runtimeShell,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: let
  outPath = placeholder "out";
  desktopItem = makeDesktopItem {
    name = finalAttrs.pname;
    desktopName = "Universal Pokemon Randomizer ZX";
    genericName = "Pokemon ROM Randomizer";
    comment = "Randomize supported Pokemon ROMs";
    exec = finalAttrs.pname;
    terminal = false;
    categories = [
      "Game"
      "Java"
    ];
    startupNotify = true;
  };
in {
  pname = "universal-pokemon-randomizer-zx";
  version = "4.6.1";

  src = fetchzip {
    url = "https://github.com/Ajarmar/universal-pokemon-randomizer-zx/releases/download/v${finalAttrs.version}/PokeRandoZX-v4_6_1.zip";
    hash = "sha256-EmK46ir/tC+R8iHRk1/1bYeZTyRgSoEKu5BXFC6t77E=";
    stripRoot = false;
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 PokeRandoZX.jar "$out/share/${finalAttrs.pname}/PokeRandoZX.jar"
    install -Dm644 README.txt "$out/share/${finalAttrs.pname}/README.txt"
    install -Dm644 ${desktopItem}/share/applications/${finalAttrs.pname}.desktop \
      "$out/share/applications/${finalAttrs.pname}.desktop"

    mkdir -p "$out/bin"
    cat > "$out/bin/${finalAttrs.pname}" <<'EOF'
    #!${runtimeShell}
    set -euo pipefail

    data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/${finalAttrs.pname}"
    mkdir -p "$data_dir"

    for file in PokeRandoZX.jar README.txt; do
      src="${outPath}/share/${finalAttrs.pname}/$file"
      dst="$data_dir/$file"
      if [ ! -e "$dst" ] || ! cmp -s "$src" "$dst"; then
        cp "$src" "$dst"
      fi
    done

    cd "$data_dir"
    exec ${lib.getExe jre} -Xmx4608M -jar "$data_dir/PokeRandoZX.jar" please-use-the-launcher
    EOF
    chmod +x "$out/bin/${finalAttrs.pname}"

    runHook postInstall
  '';

  meta = {
    description = "Universal Pokemon Randomizer ZX for Nintendo ROM randomization";
    homepage = "https://github.com/Ajarmar/universal-pokemon-randomizer-zx";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [philipp-tty];
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [binaryBytecode];
    mainProgram = finalAttrs.pname;
  };
})
