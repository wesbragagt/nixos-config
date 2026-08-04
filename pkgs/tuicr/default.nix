{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "tuicr";
  version = "0.19.1";

  src = fetchurl {
    url = "https://github.com/agavra/tuicr/releases/download/v${version}/tuicr-${version}-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-Z63azCjunG0c6EIglU8f8MaoKzdIIhQt2MthWz1CXsU=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -Dm755 tuicr $out/bin/tuicr

    runHook postInstall
  '';

  meta = {
    description = "Code review TUI with vim keybindings";
    homepage = "https://github.com/agavra/tuicr";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "tuicr";
  };
}
