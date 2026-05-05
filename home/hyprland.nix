{ ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "\$mod" = "SUPER";
      "\$term" = "foot";
      "\$browser" = "chromium";
      "\$menu" = "rofi-freq";

      monitor = "eDP-1,preferred,auto,1";

      cursor.no_hardware_cursors = true;

      env = [
        "XCURSOR_THEME,capitaine-cursors"
        "XCURSOR_SIZE,24"
      ];

      exec-once = [ "wl-paste --watch cliphist store" "waybar" "nm-applet --indicator" "nwg-dock-hyprland -p bottom -lp end -i 36 -c rofi-freq" ];

      input = {
        kb_layout = "us";
        repeat_delay = 250;
        repeat_rate = 40;
        follow_mouse = 1;
        touchpad.natural_scroll = false;
        touchpad.disable_while_typing = false;
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };

      decoration.rounding = 8;

      animations = {
        enabled = true;
        bezier = [
          "subtle, 0.16, 1, 0.3, 1"
        ];
        animation = [
          "windows, 1, 5, subtle"
          "windowsOut, 1, 5, subtle, popin 98%"
          "border, 1, 6, subtle"
          "fade, 1, 6, subtle"
          "workspaces, 1, 5, subtle, fade"
        ];
      };


      bind = [
        "\$mod, T, exec, \$term"
        "\$mod, B, exec, \$browser"
        "\$mod, E, exec, thunar"
        "\$mod, Q, killactive,"
        "\$mod, M, exit,"
        "\$mod, Space, exec, \$menu"
        "\$mod, F, fullscreen,"
        "\$mod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
        "\$mod SHIFT, V, togglefloating,"
        "\$mod, H, movefocus, l"
        "\$mod, L, movefocus, r"
        "\$mod, K, movefocus, u"
        "\$mod, J, movefocus, d"
        "\$mod, 1, workspace, 1"
        "\$mod, 2, workspace, 2"
        "\$mod, 3, workspace, 3"
        "\$mod, 4, workspace, 4"
        "\$mod, 5, workspace, 5"
        "\$mod SHIFT, 1, movetoworkspace, 1"
        "\$mod SHIFT, 2, movetoworkspace, 2"
        "\$mod SHIFT, 3, movetoworkspace, 3"
        "\$mod SHIFT, 4, movetoworkspace, 4"
        "\$mod SHIFT, 5, movetoworkspace, 5"
      ];

      bindel = [
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-"
      ];

      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];
    };
  };
}
