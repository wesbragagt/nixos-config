{
  lib,
  pkgs,
  inputs,
  hostProfile ? { },
  ...
}:
let
  isHeadless = hostProfile.headless or false;
  base = {
    imports = [
      ./repo-root.nix
      ./claude
      ./pi
      ./omp
      ./programs.nix
      ./tmux
      ./neovim
      ./sops
      inputs.sops-nix.homeManagerModules.sops
      inputs.hunk.homeManagerModules.default
      inputs.qmd.homeModules.default
    ]
    ++ lib.optionals (!isHeadless) [
      ./hyprland
      ./waybar
      ./wallpaper
      ./zen
      ./swaync.nix
      inputs.zen-browser.homeModules.beta
      inputs.chromium-webapps.homeManagerModules.default
    ];

    home.username = "wesbragagt";
    home.homeDirectory = "/home/wesbragagt";
    home.stateVersion = "25.11";

    programs.home-manager.enable = true;
    programs.qmd.enable = true;

    wes.claudeCode = {
      enable = true;
      aliases = {
        ccd = "claude --dangerously-skip-permissions";
      };
    };

    wes.pi.enable = true;

    wes.omp.enable = true;
  };
  desktop = {
    gtk = {
      enable = true;
      theme = {
        name = "Orchis-Dark";
        package = pkgs.orchis-theme;
      };
      iconTheme = {
        name = "Papirus";
        package = pkgs.papirus-icon-theme;
      };
    };

    home.pointerCursor = {
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    programs.chromium-webapps = {
      enable = true;
      webApps =
        let
          papirusIcon = name: "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/${name}.svg";
        in
        [
          {
            name = "Spotify";
            url = "https://open.spotify.com";
            icon = papirusIcon "com.spotify.Client";
          }
          {
            name = "Excalidraw";
            url = "https://excalidraw.com";
            icon = papirusIcon "excalidraw";
          }
          {
            name = "TIDAL";
            url = "https://listen.tidal.com";
            icon = papirusIcon "tidal";
          }
        ];
    };
  };
in
if isHeadless then base else lib.recursiveUpdate base desktop
