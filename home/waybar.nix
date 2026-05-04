{ ... }:
{
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];

      "hyprland/workspaces" = {
        format = "{icon}";
        on-click = "activate";
      };

      clock.format = "{:%a %b %d  %H:%M}";

      pulseaudio = {
        format = "{volume}% {icon}";
        format-muted = "muted";
        format-icons.default = [ "" "" "" ];
        on-click = "pavucontrol";
      };

      network = {
        format-wifi = "{essid} ({signalStrength}%)";
        format-ethernet = "eth";
        format-disconnected = "disconnected";
      };

      battery = {
        format = "{capacity}% {icon}";
        format-icons = [ "" "" "" "" "" ];
      };
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
      }
      window#waybar {
        background: rgba(30, 30, 46, 0.85);
        color: #cdd6f4;
      }
      #workspaces button.active {
        background: #89b4fa;
        color: #1e1e2e;
      }
    '';
  };
}
