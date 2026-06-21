{
  lib,
  stdenvNoCC,
  fetchurl,
  appimageTools,
  undmg,
}:

let
  pname = "muvel";
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  inherit (sources) version;

  meta = {
    description = "Web novel editor";
    homepage = "https://github.com/KimuSoft/muvel-public";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "muvel";
    platforms = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
in
if stdenvNoCC.hostPlatform.isLinux then
  let
    src = fetchurl {
      inherit (sources.linux.x86_64) url hash;
    };

    appimageContents = appimageTools.extractType2 {
      inherit pname version src;
    };
  in
  appimageTools.wrapType2 {
    inherit
      pname
      version
      src
      meta
      ;

    extraInstallCommands = ''
      install -Dm644 \
        ${appimageContents}/usr/share/applications/Muvel.desktop \
        $out/share/applications/muvel.desktop

      substituteInPlace $out/share/applications/muvel.desktop \
        --replace-fail 'Categories=' 'Categories=Office;'

      cp -r ${appimageContents}/usr/share/icons $out/share/
    '';
  }
else
  let
    source =
      if stdenvNoCC.hostPlatform.isAarch64 then sources.darwin.aarch64 else sources.darwin.x86_64;
  in
  stdenvNoCC.mkDerivation {
    inherit pname version meta;

    src = fetchurl {
      inherit (source) url hash;
    };

    nativeBuildInputs = [ undmg ];
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      appPath="$(find . -maxdepth 2 -type d -name Muvel.app -print -quit)"
      test -n "$appPath"
      cp -R "$appPath" $out/Applications/Muvel.app

      runHook postInstall
    '';

    # Preserve the upstream app bundle and its code signature verbatim.
    dontFixup = true;
  }
