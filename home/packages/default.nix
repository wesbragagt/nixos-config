{
  pkgs,
  inputs,
  lib,
  hostProfile ? { },
  ...
}:
let
  isLaptop = hostProfile.isLaptop or false;
  hasWireless = hostProfile.hasWireless or false;
in
{
  home.packages =
    with pkgs;
    [
      # wayland / audio
      pavucontrol
      wl-clipboard
      cliphist
      wlr-randr
      libnotify

      # screenshot / recording
      grim
      slurp
      swappy
      wf-recorder

      # cli tools
      inputs.exacli.packages.${pkgs.stdenv.hostPlatform.system}.default
      gh
      jq
      yq-go
      fd
      sesh
      uv
      python3
      stow
      tldr

      # secrets / auth
      bitwarden-desktop
      libsecret

      # desktop / ui
      gtk3
      nwg-dock-hyprland
      waypaper
      swww
      slack

      # media
      mpv
      imv

      # data
      csvlens # interactive CSV viewer
      duckdb # in-process analytical SQL
      harlequin # terminal database UI

      # git
      lazygit
      delta

      # markdown viewing
      glow

      # scripts
      (pkgs.writeShellScriptBin "rofi-bookmarks" (builtins.readFile ../../scripts/rofi-bookmarks.sh))
      (pkgs.writeShellScriptBin "rofi-freq" (builtins.readFile ../../scripts/rofi-freq.sh))
      (pkgs.writeShellScriptBin "sf" (builtins.readFile ../../scripts/sf.sh))
      (pkgs.writeShellScriptBin "sg" (builtins.readFile ../../scripts/sg.sh))
      (pkgs.writeShellScriptBin "wf-record" (builtins.readFile ../../scripts/wf-recorder.sh))
      (pkgs.writeShellScriptBin "bw-ssh-load" ''
        exec ${pkgs.python3}/bin/python3 ${../../scripts/bw-ssh-load.py} "$@"
      '')
      (pkgs.callPackage ../../pkgs/workmux { })
    ]
    ++ lib.optionals hasWireless [
      # network / Wi-Fi tray helpers
      networkmanagerapplet
      iwgtk
    ]
    ++ lib.optionals isLaptop [
      (pkgs.writeShellScriptBin "battery-estimate" (builtins.readFile ../../scripts/battery-estimate.sh))
    ];
}
