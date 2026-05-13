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
  # Python wheels loaded via the Nix-managed interpreter use dlopen(), so they
  # need LD_LIBRARY_PATH directly; nix-ld alone only helps foreign executables.
  wrappedPython = pkgs.symlinkJoin {
    name = "python3-wrapped";
    paths = [ pkgs.python3 ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in "$out"/bin/python*; do
        if [ -f "$bin" ] && [ -x "$bin" ]; then
          wrapProgram "$bin" --prefix LD_LIBRARY_PATH : /run/current-system/sw/share/nix-ld/lib
        fi
      done
    '';
  };
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
      wrappedPython
      stow
      tldr
      (pkgs.callPackage ../../pkgs/agent-browser { })

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
      playerctl
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
      (pkgs.writeShellScriptBin "edit-bookmarks" (builtins.readFile ../../scripts/edit-bookmarks.sh))
      (pkgs.writeShellScriptBin "rofi-freq" (builtins.readFile ../../scripts/rofi-freq.sh))
      (pkgs.writeShellScriptBin "file-fzf" (builtins.readFile ../../scripts/sf.sh))
      (pkgs.writeShellScriptBin "grep-fzf" (builtins.readFile ../../scripts/sg.sh))
      (pkgs.writeShellScriptBin "wf-record" (builtins.readFile ../../scripts/wf-recorder.sh))
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
