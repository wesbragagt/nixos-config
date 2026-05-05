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
  security.pam.services.hyprlock = { };
  services.actkbd = {
    enable = true;
    bindings = [
      {
        keys = [ 224 ];
        events = [ "key" "rep" ];
        command = "${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
      }
      {
        keys = [ 225 ];
        events = [ "key" "rep" ];
        command = "${pkgs.brightnessctl}/bin/brightnessctl set 5%+";
      }
      {
        keys = [ 114 ];
        events = [ "key" "rep" ];
        command = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-";
      }
      {
        keys = [ 115 ];
        events = [ "key" "rep" ];
        command = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+";
      }
      {
        keys = [ 113 ];
        events = [ "key" ];
        command = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      }
      {
        keys = [ 248 ];
        events = [ "key" ];
        command = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      }
    ];
  };
  services.dbus.enable = true;

  environment.systemPackages = with pkgs; [ brightnessctl ];
  services.udev.packages = with pkgs; [ brightnessctl ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
