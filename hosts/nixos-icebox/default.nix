{ lib, pkgs, ... }:

let
  hardwareConfig = ./hardware-configuration.nix;
in
{
  imports = (lib.optional (builtins.pathExists hardwareConfig) hardwareConfig) ++ [
    ../../common.nix
  ];

  assertions = lib.optional (!(builtins.pathExists hardwareConfig)) {
    assertion = false;
    message = ''
      nixos-icebox is missing hosts/nixos-icebox/hardware-configuration.nix.
      Generate it on nixos-icebox with:
        sudo nixos-generate-config --show-hardware-config > hosts/nixos-icebox/hardware-configuration.nix
    '';
  };

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Identity
  networking.hostName = "nixos-icebox";

  system.stateVersion = "25.11";
}
