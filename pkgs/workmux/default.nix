{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname   = "workmux";
  version = "0.1.200";

  src = fetchurl {
    url    = "https://github.com/raine/workmux/releases/download/v${version}/workmux-linux-amd64.tar.gz";
    sha256 = "10lcc4vfb51aj7yz69v80gzbz8yhfdk2kb5cym0gzch12fjry718";
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    install -m755 workmux $out/bin/workmux
  '';
}
