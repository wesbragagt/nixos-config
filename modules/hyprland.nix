{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  security.polkit.enable = true;
  services.dbus.enable = true;

  environment.systemPackages = with pkgs; [ brightnessctl ];
  services.udev.packages = with pkgs; [ brightnessctl ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
