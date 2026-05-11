{
  pkgs,
  lib,
  config,
  repoRoot,
  hostProfile ? { },
  ...
}:
let
  hyprlandSourceDir = "${repoRoot}/home/hyprland";
  isLaptop = hostProfile.isLaptop or false;
  hasWireless = hostProfile.hasWireless or false;
  swapAltSuper = hostProfile.swapAltSuper or true;
  hypridle = {
    lockTimeout = 300;
    dpmsTimeout = 330;
    suspendTimeout = null;
    suspendRequiresNoSsh = false;
  }
  // (hostProfile.hypridle or { });
  hyprlandConfig =
    if isLaptop && swapAltSuper then
      "hyprland.conf"
    else if isLaptop then
      "hyprland-noswap.conf"
    else if hasWireless && swapAltSuper then
      "hyprland-desktop-wireless.conf"
    else if hasWireless then
      "hyprland-desktop-wireless-noswap.conf"
    else if swapAltSuper then
      "hyprland-desktop.conf"
    else
      "hyprland-desktop-noswap.conf";
  reloadHyprland = ''
    (
      XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
      if [[ -d "/tmp/hypr" || -d "$XDG_RUNTIME_DIR/hypr" ]]; then
        for i in $(${config.wayland.windowManager.hyprland.finalPackage}/bin/hyprctl instances -j | jq ".[].instance" -r); do
          ${config.wayland.windowManager.hyprland.finalPackage}/bin/hyprctl -i "$i" reload config-only
        done
      fi
    )
  '';
  suspendIfNoSsh = pkgs.writeShellScriptBin "suspend-if-no-ssh" ''
    set -euo pipefail

    has_ssh_session=0
    while read -r session_id _; do
      [[ -n "$session_id" ]] || continue
      session_props="$(${pkgs.systemd}/bin/loginctl show-session "$session_id" -p Remote -p Service --no-pager 2>/dev/null || true)"
      if grep -qx 'Remote=yes' <<< "$session_props" || grep -qx 'Service=sshd' <<< "$session_props"; then
        has_ssh_session=1
        break
      fi
    done < <(${pkgs.systemd}/bin/loginctl list-sessions --no-legend 2>/dev/null || true)

    if [[ "$has_ssh_session" -eq 1 ]]; then
      ${pkgs.systemd}/bin/systemd-cat -t hypridle-suspend-if-no-ssh echo "Skipping idle suspend: SSH session active"
      exit 0
    fi

    ${pkgs.systemd}/bin/systemctl suspend
  '';
  suspendCommand =
    if hypridle.suspendRequiresNoSsh then
      "${suspendIfNoSsh}/bin/suspend-if-no-ssh"
    else
      "systemctl suspend";
in
{
  home.packages = with pkgs; [ hyprlock ];

  xdg.configFile."hypr/hyprlock.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${hyprlandSourceDir}/hyprlock.conf";
  };

  xdg.configFile."hypr/hyprland.conf" = lib.mkForce {
    source = config.lib.file.mkOutOfStoreSymlink "${hyprlandSourceDir}/${hyprlandConfig}";
    onChange = reloadHyprland;
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
          timeout = hypridle.lockTimeout;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = hypridle.dpmsTimeout;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ]
      ++ lib.optionals (hypridle.suspendTimeout != null) [
        {
          timeout = hypridle.suspendTimeout;
          on-timeout = suspendCommand;
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
