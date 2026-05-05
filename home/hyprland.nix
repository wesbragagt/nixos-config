{ pkgs, ... }:
{
  home.packages = with pkgs; [ hyprlock ];

  xdg.configFile."hypr/hyprlock.conf".text = ''
    $font = JetBrainsMono Nerd Font

    general {
        hide_cursor = true
    }

    background {
        monitor =
        path = screenshot
        blur_passes = 4
        blur_size = 5
        noise = 0.0117
        contrast = 1.2
        brightness = 0.8
        vibrancy = 0.18
        vibrancy_darkness = 0.0
    }

    label {
        monitor =
        text = $TIME
        color = rgba(ebdcffff)
        font_size = 88
        font_family = $font
        position = 0, 140
        halign = center
        valign = center
    }

    label {
        monitor =
        text = cmd[update:60000] date +"%A, %B %d"
        color = rgba(cdd6f4ff)
        font_size = 24
        font_family = Noto Sans
        position = 0, 70
        halign = center
        valign = center
    }

    label {
        monitor =
        text = Hi wesbragagt
        color = rgba(a6e3a1ff)
        font_size = 20
        font_family = Noto Sans
        position = 0, -80
        halign = center
        valign = center
    }

    input-field {
        monitor =
        size = 260, 56
        outline_thickness = 2
        dots_size = 0.22
        dots_spacing = 0.2
        dots_center = true
        fade_on_empty = false
        font_color = rgba(cdd6f4ff)
        inner_color = rgba(1e1e2eb8)
        outer_color = rgba(cba6f7e6)
        check_color = rgba(a6e3a1e6)
        fail_color = rgba(f38ba8e6)
        placeholder_text = Password
        fail_text = $PAMFAIL
        rounding = 14
        position = 0, -150
        halign = center
        valign = center
    }
  '';

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

      exec-once = [
        "[workspace 1 silent] foot"
        "[workspace 2 silent] chromium"
        "[workspace 5 silent] bitwarden"
        "wl-paste --watch cliphist store"
        "waybar"
        "nm-applet --indicator"
        "nwg-dock-hyprland -p bottom -lp end -i 36 -c rofi-freq"
        "swaync"
        "swww-daemon"
      ];

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
        border_size = 0;
        "col.active_border" = "rgba(00000000)";
        "col.inactive_border" = "rgba(00000000)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        shadow = {
          enabled = true;
          range = 18;
          render_power = 3;
          color = "rgba(00000066)";
          color_inactive = "rgba(00000022)";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "subtle, 0.16, 1, 0.3, 1"
        ];
        animation = [
          "windows, 1, 5, subtle"
          "windowsOut, 1, 5, subtle, slide"
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
        "\$mod, Escape, exec, loginctl lock-session"
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
        "\$mod, 6, workspace, 6"
        "\$mod, 7, workspace, 7"
        "\$mod, 8, workspace, 8"
        "\$mod, 9, workspace, 9"
        "\$mod SHIFT, 6, movetoworkspace, 6"
        "\$mod SHIFT, 7, movetoworkspace, 7"
        "\$mod SHIFT, 8, movetoworkspace, 8"
        "\$mod SHIFT, 9, movetoworkspace, 9"
        "\$mod SHIFT, BackSpace, exec, waypaper"
        "\$mod SHIFT, minus, exec, pkill -35 nwg-dock-hyprland"
      ];

      windowrulev2 = [
        "float, class:^(waypaper)$"
        "size 480 768, class:^(waypaper)$"
        "move 886 0, class:^(waypaper)$"
        "animation slide, class:^(waypaper)$"
        "opacity 0.85 0.85, class:^(waypaper)$"
      ];

      bindel = [ ];

      bindl = [ ];
    };
  };
}
