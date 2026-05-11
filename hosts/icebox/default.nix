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
      icebox is missing hosts/icebox/hardware-configuration.nix.
      Generate it on icebox with:
        sudo nixos-generate-config --show-hardware-config > hosts/icebox/hardware-configuration.nix
    '';
  };

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Identity
  networking.hostName = "icebox";

  system.stateVersion = "25.11";
}
