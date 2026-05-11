{ lib, ... }:

{
  options.wes.host = {
    isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this host has laptop-only hardware such as a lid, battery, backlight keys, and touchpad.";
    };

    hasWireless = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to install and launch Wi-Fi-oriented desktop UI helpers.";
    };

    graphics = lib.mkOption {
      type = lib.types.enum [
        "generic"
        "intel"
        "amd"
        "nvidia"
      ];
      default = "generic";
      description = "Host graphics profile used for hardware acceleration packages and environment defaults.";
    };

    swapAltSuper = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether Hyprland should swap left Alt and left Super for this host.";
    };

    sopsHostKeyPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/etc/ssh/ssh_host_ed25519_key";
      description = ''
        Host SSH private key path used by sops-nix for unattended system
        secret decryption. Leave null for bootstrap installs before the host
        key has been generated and added as a recipient.
      '';
    };
  };
}
