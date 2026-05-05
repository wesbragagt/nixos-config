{ ... }:
{
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 26;
      margin-top = 4;
      margin-left = 8;
      margin-right = 8;
      spacing = 6;

      modules-left = [ "custom/logo" "cpu" "memory" "disk" ];
      modules-center = [ "hyprland/workspaces" ];
      modules-right = [ "pulseaudio" "custom/battery" "clock" "tray" ];

      "custom/logo" = {
        format = "❄";
        tooltip = false;
        on-click = "rofi-freq";
      };

      cpu = {
        interval = 5;
        format = "🧠 {usage}%";
        tooltip = true;
      };

      memory = {
        interval = 5;
        format = "💾 {percentage}%";
        tooltip-format = "{used:0.1f}G / {total:0.1f}G";
      };

      disk = {
        interval = 30;
        format = "🗄 {percentage_used}%";
        path = "/";
        tooltip-format = "{used} / {total} on {path}";
      };

      "hyprland/workspaces" = {
        format = "{name}";
        on-click = "activate";
        all-outputs = true;
        sort-by-number = true;
      };

      clock = {
        format = "🕐 {:%a, %d %b, %I:%M %p}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-bluetooth = "🎧 {volume}%";
        format-muted = "🔇";
        format-icons = {
          headphone = "🎧";
          headset = "🎧";
          default = [ "🔈" "🔉" "🔊" ];
        };
        on-click = "pavucontrol";
      };

      "custom/battery" = {
        exec = "battery-estimate";
        return-type = "json";
        interval = 15;
        tooltip = true;
      };

      tray = {
        icon-size = 16;
        spacing = 8;
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", "Noto Color Emoji";
        font-size: 12px;
        font-weight: 500;
        min-height: 0;
        border: none;
        border-radius: 0;
        padding: 0;
        margin: 0;
      }

      window#waybar {
        background: transparent;
        color: #cdd6f4;
      }

      #custom-logo,
      #workspaces,
      #cpu,
      #memory,
      #disk,
      #network,
      #pulseaudio,
      #custom-battery,
      #clock,
      #tray {
        background: rgba(17, 17, 27, 0.85);
        color: #cdd6f4;
        padding: 1px 10px;
        border-radius: 999px;
        margin: 0 2px;
      }

      #custom-logo {
        color: #89b4fa;
        font-size: 16px;
        padding: 4px 14px;
      }

      #workspaces {
        padding: 3px 6px;
      }
      #workspaces button {
        color: #cdd6f4;
        background: transparent;
        padding: 0 10px;
        margin: 0 2px;
        border-radius: 999px;
        min-width: 22px;
        transition: all 200ms ease;
      }
      #workspaces button:hover {
        background: rgba(137, 180, 250, 0.15);
        box-shadow: none;
        text-shadow: none;
      }
      #workspaces button.active {
        background: rgba(137, 180, 250, 0.25);
        color: #cdd6f4;
        padding: 0 14px;
      }
      #workspaces button.urgent {
        background: rgba(243, 139, 168, 0.4);
        color: #1e1e2e;
      }

      #network.disconnected { color: #f38ba8; }
      #pulseaudio.muted { color: #6c7086; }
      #custom-battery.warning { color: #f9e2af; }
      #custom-battery.critical { color: #f38ba8; }
      #custom-battery.charging { color: #a6e3a1; }

      #tray { padding: 4px 10px; }
      #tray > .passive { -gtk-icon-effect: dim; }
    '';
  };
}
