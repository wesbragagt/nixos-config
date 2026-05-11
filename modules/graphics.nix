{
  config,
  lib,
  pkgs,
  ...
}:
let
  graphics = config.wes.host.graphics;
in
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = lib.optionals (graphics == "intel") [
      pkgs.intel-media-driver
      pkgs.intel-vaapi-driver
      pkgs.libva-vdpau-driver
      pkgs.libvdpau-va-gl
    ];
  };

  environment.sessionVariables = lib.optionalAttrs (graphics == "intel") {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
