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
  };
}
