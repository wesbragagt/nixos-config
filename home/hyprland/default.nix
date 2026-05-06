{ pkgs, lib, config, ... }:
let
  hyprlandSourceDir = "${config.home.homeDirectory}/nixos-config/home/hyprland";
in
{
  home.packages = with pkgs; [ hyprlock ];

  xdg.configFile."hypr/hyprlock.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${hyprlandSourceDir}/hyprlock.conf";
  };

  xdg.configFile."hypr/hyprland.conf" = lib.mkForce {
    source = config.lib.file.mkOutOfStoreSymlink "${hyprlandSourceDir}/hyprland.conf";
    onChange = ''
      (
        XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
        if [[ -d "/tmp/hypr" || -d "$XDG_RUNTIME_DIR/hypr" ]]; then
          for i in $(${config.wayland.windowManager.hyprland.finalPackage}/bin/hyprctl instances -j | jq ".[].instance" -r); do
            ${config.wayland.windowManager.hyprland.finalPackage}/bin/hyprctl -i "$i" reload config-only
          done
        fi
      )
    '';
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;

    # Keep Home Manager's Hyprland session wiring enabled while the actual
    # config file is owned by the out-of-store symlink above.
    extraConfig = "# managed via xdg.configFile.\"hypr/hyprland.conf\"";
  };
}
