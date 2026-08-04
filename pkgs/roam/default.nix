{
  stdenv,
  fetchurl,
  lib,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libappindicator-gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libpulseaudio,
  libsecret,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  pipewire,
  wireplumber,
  xdg-desktop-portal,
  xdg-desktop-portal-hyprland,
  systemd,
  xdg-utils,
  xorg,
}:

stdenv.mkDerivation rec {
  pname = "roam";
  version = "224.0.0-beta001";

  src = fetchurl {
    url = "https://download.ro.am/Roam/8a86d88cfc9da3551063102e9a4e2a83/linux/debian/binary/${version}-roam_${version}_amd64.deb";
    hash = "sha256-IwP4U/X9EKkMpGG1niHr+LyqHgapSZUX+283k/r46Ks=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libappindicator-gtk3
    libdrm
    libgbm
    libglvnd
    libnotify
    libpulseaudio
    libsecret
    libxkbcommon
    mesa
    nspr
    nss
    pango
    pipewire
    wireplumber
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    systemd
    xdg-utils
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
  ];

  unpackPhase = ''
    runHook preUnpack
    ar x $src
    tar -xf data.tar.xz
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin $out/share
    cp -a usr/lib/roam $out/lib/roam
    cp -a usr/share/applications $out/share/
    cp -a usr/share/icons $out/share/

    substituteInPlace $out/share/applications/roam.desktop \
      --replace-fail "Exec=roam %U" "Exec=$out/bin/roam %U"

    makeWrapper $out/lib/roam/Roam $out/bin/roam \
      --prefix PATH : ${
        lib.makeBinPath [
          pipewire
          wireplumber
          xdg-desktop-portal
          xdg-desktop-portal-hyprland
          xdg-utils
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --set-default NIXOS_OZONE_WL 1 \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer"

    runHook postInstall
  '';

  meta = {
    description = "Roam: AI-Powered Virtual HQ";
    homepage = "https://ro.am";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "roam";
  };
}
