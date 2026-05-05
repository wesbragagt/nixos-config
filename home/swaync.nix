{ ... }:
{
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "application";
      control-center-margin-top = 8;
      control-center-margin-bottom = 0;
      control-center-margin-right = 8;
      control-center-margin-left = 0;
      notification-2fa-action = true;
      notification-inline-replies = false;
      notification-icon-size = 48;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 5;
      timeout-low = 3;
      timeout-critical = 0;
      fit-to-screen = false;
      control-center-width = 340;
      control-center-height = 600;
      notification-window-width = 340;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;
      widgets = [ "inhibitors" "title" "dnd" "notifications" ];
      widget-config = {
        inhibitors = {
          text = "Inhibitors";
          button-text = "Clear All";
          clear-all-button = true;
        };
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd = {
          text = "Do Not Disturb";
        };
        label = {
          max-lines = 1;
          text = "Notification Center";
        };
        mpris = {
          image-size = 96;
          image-radius = 8;
        };
      };
    };
    style = ''
      * {
        font-family: JetBrainsMono Nerd Font, monospace;
        font-size: 13px;
      }

      .notification-row {
        outline: none;
      }

      .notification-row:focus,
      .notification-row:hover {
        background: rgba(49, 50, 68, 0.6);
      }

      .notification {
        background: rgba(30, 30, 46, 0.95);
        border-radius: 10px;
        margin: 6px 12px;
        padding: 0;
        border: 1px solid rgba(137, 180, 250, 0.15);
      }

      .notification-content {
        padding: 10px;
        border-radius: 10px;
      }

      .close-button {
        background: transparent;
        color: #6c7086;
        border-radius: 999px;
        padding: 2px;
        margin: 4px;
        border: none;
      }

      .close-button:hover {
        background: rgba(243, 139, 168, 0.2);
        color: #f38ba8;
      }

      .notification-default-action {
        background: transparent;
        border-radius: 10px;
        padding: 0;
        margin: 0;
        border: none;
      }

      .notification-default-action:hover {
        background: rgba(137, 180, 250, 0.08);
      }

      .notification-summary {
        color: #cdd6f4;
        font-weight: 600;
        font-size: 13px;
      }

      .notification-time {
        color: #6c7086;
        font-size: 11px;
      }

      .notification-body {
        color: #bac2de;
        font-size: 12px;
      }

      .notification-action-button {
        background: rgba(49, 50, 68, 0.8);
        color: #cdd6f4;
        border-radius: 6px;
        border: 1px solid rgba(137, 180, 250, 0.15);
        margin: 4px;
      }

      .notification-action-button:hover {
        background: rgba(137, 180, 250, 0.15);
      }

      .image {
        border-radius: 6px;
      }

      .control-center {
        background: rgba(24, 24, 37, 0.97);
        border-radius: 12px;
        border: 1px solid rgba(137, 180, 250, 0.15);
        padding: 8px;
      }

      .control-center-list {
        background: transparent;
      }

      .control-center-list-placeholder {
        color: #585b70;
        font-size: 13px;
      }

      .floating-notifications {
        background: transparent;
      }

      .blank-window {
        background: alpha(black, 0.1);
      }

      .widget-title {
        color: #cdd6f4;
        font-weight: 700;
        font-size: 14px;
        margin: 4px 8px;
      }

      .widget-title > button {
        background: rgba(49, 50, 68, 0.8);
        color: #6c7086;
        border-radius: 6px;
        border: none;
        padding: 4px 10px;
        font-size: 12px;
      }

      .widget-title > button:hover {
        background: rgba(243, 139, 168, 0.15);
        color: #f38ba8;
      }

      .widget-dnd {
        color: #cdd6f4;
        margin: 4px 8px;
        font-size: 13px;
      }

      .widget-dnd > switch {
        border-radius: 999px;
        background: rgba(49, 50, 68, 0.8);
        border: 1px solid rgba(137, 180, 250, 0.2);
      }

      .widget-dnd > switch:checked {
        background: #89b4fa;
      }

      .widget-dnd > switch slider {
        background: #cdd6f4;
        border-radius: 999px;
      }

      .widget-inhibitors {
        color: #cdd6f4;
        margin: 4px 8px;
        font-size: 13px;
      }

      .widget-inhibitors > button {
        background: rgba(49, 50, 68, 0.8);
        color: #6c7086;
        border-radius: 6px;
        border: none;
        padding: 4px 10px;
        font-size: 12px;
      }

      .widget-inhibitors > button:hover {
        background: rgba(243, 139, 168, 0.15);
        color: #f38ba8;
      }
    '';
  };
}
