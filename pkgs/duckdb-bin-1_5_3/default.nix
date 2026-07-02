{
  stdenv,
  fetchurl,
  unzip,
  lib,
}:

stdenv.mkDerivation rec {
  pname = "duckdb-bin";
  version = "1.5.3";

  src = fetchurl {
    url = "https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_cli-linux-amd64.zip";
    hash = "sha256-NcrvH+y8jX4sB95P0s3vxRieybqeHMoij7GhxIzFKoo=";
  };

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    runHook preUnpack
    unzip "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 duckdb "$out/bin/duckdb"
    runHook postInstall
  '';

  meta = {
    description = "DuckDB command-line client binary";
    homepage = "https://duckdb.org/";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "duckdb";
  };
}
