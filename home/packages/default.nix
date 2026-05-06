{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
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

    # network
    networkmanagerapplet
    iwgtk

    # browsers
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # cli tools
    inputs.exacli.packages.${pkgs.stdenv.hostPlatform.system}.default
    gh
    jq
    yq-go
    fd
    sesh
    uv
    python3

    # secrets / auth
    bitwarden-desktop
    libsecret

    # desktop / ui
    gtk3
    nwg-dock-hyprland
    waypaper
    swww

    # media
    mpv
    imv

    # data
    csvlens     # interactive CSV viewer
    duckdb      # in-process analytical SQL
    harlequin   # terminal database UI

    # git
    lazygit
    delta

    # markdown viewing
    glow

    # scripts
    (pkgs.writeShellScriptBin "rofi-freq" (builtins.readFile ../../scripts/rofi-freq.sh))
    (pkgs.writeShellScriptBin "sf" (builtins.readFile ../../scripts/sf.sh))
    (pkgs.writeShellScriptBin "sgrep" (builtins.readFile ../../scripts/sg.sh))
    (pkgs.writeShellScriptBin "battery-estimate" (builtins.readFile ../../scripts/battery-estimate.sh))
    (pkgs.writeShellScriptBin "wf-record" (builtins.readFile ../../scripts/wf-recorder.sh))
    (pkgs.callPackage ../../pkgs/workmux {})
  ];
}
