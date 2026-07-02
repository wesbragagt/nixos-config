{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  wrapGAppsHook3,
  cairo,
  fontconfig,
  gdk-pixbuf,
  glib,
  gtk3,
  libsoup_3,
  webkitgtk_4_1,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "openpencil-desktop";
  version = "0.13.2";

  src = fetchurl {
    url = "https://github.com/open-pencil/open-pencil/releases/download/v${finalAttrs.version}/OpenPencil_${finalAttrs.version}_amd64.deb";
    hash = "sha256-HKMB4eTC6WL24COnaAMYQf/Em77FO8hviotUrYwmsZQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    wrapGAppsHook3
  ];

  buildInputs = [
    cairo
    fontconfig
    gdk-pixbuf
    glib
    gtk3
    libsoup_3
    webkitgtk_4_1
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 usr/bin/OpenPencil $out/bin/openpencil-desktop

    install -Dm644 usr/share/applications/OpenPencil.desktop \
      $out/share/applications/openpencil-desktop.desktop
    substituteInPlace $out/share/applications/openpencil-desktop.desktop \
      --replace-fail 'Exec=OpenPencil' 'Exec=openpencil-desktop %U' \
      --replace-fail 'Icon=OpenPencil' 'Icon=openpencil-desktop' \
      --replace-fail 'Categories=' 'Categories=Graphics;Development;'

    for icon in usr/share/icons/hicolor/*/apps/OpenPencil.png; do
      size="$(basename "$(dirname "$(dirname "$icon")")")"
      install -Dm644 "$icon" \
        "$out/share/icons/hicolor/$size/apps/openpencil-desktop.png"
    done

    runHook postInstall
  '';

  meta = {
    description = "Open-source design editor desktop app";
    homepage = "https://openpencil.dev";
    downloadPage = "https://github.com/open-pencil/open-pencil/releases";
    changelog = "https://github.com/open-pencil/open-pencil/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "openpencil-desktop";
  };
})
