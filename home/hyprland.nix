{ ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "\$mod" = "SUPER";
      "\$term" = "kitty";
      "\$browser" = "chromium";
      "\$menu" = "rofi-freq";

      monitor = ",preferred,auto,1";

      cursor.no_hardware_cursors = true;

      env = [
        "XCURSOR_THEME,capitaine-cursors"
        "XCURSOR_SIZE,24"
      ];

      exec-once = [ "waybar" "nm-applet --indicator" "nwg-dock-hyprland -p bottom -lp end -i 36 -c rofi-freq" ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad.natural_scroll = false;
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
          "snappy, 0.25, 0.46, 0.45, 0.94"
        ];
        animation = [
          "windows, 1, 2, snappy"
          "windowsOut, 1, 2, snappy, popin 95%"
          "border, 1, 2, snappy"
          "fade, 1, 3, snappy"
          "workspaces, 1, 3, snappy, fade"
        ];
      };


      bind = [
        "\$mod, Return, exec, \$term"
        "\$mod, B, exec, \$browser"
        "\$mod, Q, killactive,"
        "\$mod, M, exit,"
        "\$mod, Space, exec, \$menu"
        "\$mod, F, fullscreen,"
        "\$mod, V, togglefloating,"
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
    };
  };
}
