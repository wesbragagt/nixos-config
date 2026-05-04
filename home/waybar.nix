{ ... }:
{
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 32;
      spacing = 6;
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];

      "hyprland/workspaces" = {
        format = "{icon}";
        on-click = "activate";
        format-icons = {
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          urgent = "";
          default = "";
          active = "";
        };
      };

      clock = {
        format = "{:%a %b %d  %H:%M}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      pulseaudio = {
        format = "{volume}% {icon}";
        format-bluetooth = "{volume}% {icon} ";
        format-muted = "";
        format-icons = {
          headphone = "";
          hands-free = "";
          headset = "";
          phone = "";
          portable = "";
          car = "";
          default = [ "" "" "" ];
        };
        on-click = "pavucontrol";
      };

      network = {
        format-wifi = "{essid} {signalStrength}% {icon}";
        format-ethernet = "{ipaddr}/{cidr} ";
        format-linked = "{ifname} (No IP) ";
        format-disconnected = "disconnected ";
        format-icons = [ "" "" "" "" "" ];
        tooltip-format = "{ifname} via {gwaddr}";
        tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}";
        tooltip-format-disconnected = "Disconnected";
        on-click = "kitty --class waybar-popup -e nmtui";
        on-click-right = "iwgtk";
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{capacity}% {icon}";
        format-charging = "{capacity}% ";
        format-plugged = "{capacity}% ";
        format-alt = "{time} {icon}";
        format-icons = [ "" "" "" "" "" ];
      };

      tray = {
        icon-size = 18;
        spacing = 8;
      };
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(30, 30, 46, 0.92);
        color: #cdd6f4;
        border-bottom: 1px solid #45475a;
      }

      #workspaces button {
        padding: 0 8px;
        color: #cdd6f4;
        background: transparent;
        border-radius: 4px;
      }
      #workspaces button.active {
        background: #89b4fa;
        color: #1e1e2e;
      }
      #workspaces button.urgent {
        background: #f38ba8;
        color: #1e1e2e;
      }

      #clock,
      #pulseaudio,
      #network,
      #battery,
      #tray {
        padding: 0 10px;
        margin: 4px 2px;
        background: rgba(49, 50, 68, 0.85);
        color: #cdd6f4;
        border-radius: 6px;
      }

      #battery.warning {
        background: #f9e2af;
        color: #1e1e2e;
      }
      #battery.critical {
        background: #f38ba8;
        color: #1e1e2e;
      }
      #battery.charging {
        background: #a6e3a1;
        color: #1e1e2e;
      }

      #network.disconnected {
        background: #f38ba8;
        color: #1e1e2e;
      }
    '';
  };
}
