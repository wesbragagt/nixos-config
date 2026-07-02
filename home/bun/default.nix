{ lib, pkgs, ... }:
{
  home.packages = [
    (pkgs.callPackage ../../pkgs/bun-bin-1_3_14 { })
  ];

  home.sessionVariables = {
    BUN_INSTALL = "$HOME/.bun";
  };

  home.sessionPath = [
    "$HOME/.bun/bin"
  ];

  home.activation.ensureBunGlobalDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.bun/bin"
  '';
}
