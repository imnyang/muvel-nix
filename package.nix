{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  wrapGAppsHook3,
  webkitgtk_4_1,
  gtk3,
  glib,
  glib-networking,
  cairo,
  dbus,
  fontconfig,
  gdk-pixbuf,
  undmg,
}:

let
  pname = "muvel";
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  inherit (sources) version;

  meta = {
    description = "A storytelling tool for everyone";
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
if stdenv.hostPlatform.isLinux then
  stdenv.mkDerivation {
    inherit pname version meta;

    src = fetchurl {
      inherit (sources.linux.x86_64) url hash;
    };

    nativeBuildInputs = [
      autoPatchelfHook
      dpkg
      wrapGAppsHook3
    ];

    buildInputs = [
      webkitgtk_4_1
      gtk3
      glib
      glib-networking
      cairo
      dbus
      fontconfig
      gdk-pixbuf
      stdenv.cc.cc.lib
    ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --extract $src .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r usr/bin usr/lib usr/share $out/
      substituteInPlace $out/share/applications/Muvel.desktop \
        --replace-fail 'Categories=' 'Categories=Office;'
      substituteInPlace $out/share/applications/Muvel.desktop \
        --replace-fail 'Exec=muvel' 'Exec=muvel %u' \
        --replace-fail 'x-scheme-handler/muvel' 'x-scheme-handler/muvel;'

      runHook postInstall
    '';

    # WebKit's DMA-BUF path is incompatible with the NVIDIA driver. Transfer
    # frames through SHM while retaining the session's native GDK backend.
    preFixup = ''
      gappsWrapperArgs+=(--set WEBKIT_DMABUF_RENDERER_FORCE_SHM 1)
      gappsWrapperArgs+=(--unset GTK_IM_MODULE)
      gappsWrapperArgs+=(--set GTK_USE_PORTAL 1)
    '';
  }
else
  let
    source = if stdenv.hostPlatform.isAarch64 then sources.darwin.aarch64 else sources.darwin.x86_64;
  in
  stdenv.mkDerivation {
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
