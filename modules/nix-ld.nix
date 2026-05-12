{ pkgs, ... }:
{
  # nix-ld lets unpatched dynamically-linked binaries (Python wheels like
  # pyarrow / duckdb / pandas, Node prebuilts, language servers, etc.) find
  # their .so dependencies on NixOS without per-shell LD_LIBRARY_PATH hacks.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib   # libstdc++.so.6 — pyarrow, duckdb, many ML wheels
    zlib
    openssl
    glib
    icu
    libGL
    xz
    libxcrypt-legacy
    bzip2
  ];
}
