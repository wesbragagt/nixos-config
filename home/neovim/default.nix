{ pkgs, lib, config, inputs, ... }:
let
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  lspRegistry = builtins.fromJSON (builtins.readFile ./config/lsp-registry.json);

  resolvePackage = attrPath:
    lib.attrByPath attrPath
      (throw "home/neovim: unknown package attr path ${lib.concatStringsSep "." attrPath}")
      pkgs;

  lspPackages = lib.unique (
    lib.flatten (
      lib.mapAttrsToList (_: server:
        map resolvePackage ([ server.packageAttrPath ] ++ (server.extraPackageAttrPaths or [ ]))
      ) lspRegistry
    )
  );
in
{
  home.packages = [
    unstable.neovim
    pkgs.git
    pkgs.ripgrep
    pkgs.fd
    pkgs.gcc
    pkgs.nodejs
    pkgs.bat
  ] ++ lspPackages;

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-config/home/neovim/config";
}
