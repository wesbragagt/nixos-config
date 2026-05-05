{ pkgs, config, inputs, ... }:
let
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
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
    pkgs.lua-language-server
    pkgs.nodePackages.typescript-language-server
    pkgs.pyright
    pkgs.nixd
    pkgs.yaml-language-server
    pkgs.tofu-ls
  ];

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-config/nvim";
}
