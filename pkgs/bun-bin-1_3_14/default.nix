{ stdenvNoCC, fetchzip, lib }:

stdenvNoCC.mkDerivation rec {
  pname = "bun-bin";
  version = "1.3.14";

  src = fetchzip {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
    hash = "sha256-YyGDD7f0JlmiO2G3LY80p/oMUpWXcoC7x7LW/gU/LmU=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src/bun-linux-x64/bun" "$out/bin/bun"

    runHook postInstall
  '';

  meta = {
    description = "Fast JavaScript runtime, package manager, bundler and test runner";
    homepage = "https://bun.sh";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "bun";
  };
}
