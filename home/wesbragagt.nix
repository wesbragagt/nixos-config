{
  lib,
  pkgs,
  inputs,
  hostProfile ? { },
  ...
}:
let
  isHeadless = hostProfile.headless or false;
  features = hostProfile.features or { };
  claudeCodeEnabled = features.claude-code or false;
  ompEnabled = features.omp or false;
  mnemosyneEnabled = features.mnemosyne or false;
  base = {
    imports = [
      ./repo-root.nix
      ./claude
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
    wes.claudeCode = {
      enable = claudeCodeEnabled;
      aliases = {
        ccd = "claude --dangerously-skip-permissions";
      };
    };

    wes.omp.enable = ompEnabled;
    home.packages = [ pkgs.nssTools ];
    home.sessionVariables = lib.optionalAttrs mnemosyneEnabled {
      MNEMOSYNE_DATA_DIR = "/home/wesbragagt/.local/share/mnemosyne";
      MNEMOSYNE_BANK = "default";
    };

    systemd.user.services.caddy-local-trust = lib.mkIf (!isHeadless) {
      Unit = {
        Description = "Import Caddy local CA into Chromium trust store";
        After = [ "graphical-session.target" ];
        Wants = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = pkgs.writeShellScript "import-caddy-local-ca" ''
          set -eu
          root_ca=/run/caddy-local-root.crt
          nssdb="$HOME/.pki/nssdb"

          for attempt in $(seq 1 30); do
            if [ -s "$root_ca" ]; then
              break
            fi
            sleep 2
          done

          test -s "$root_ca"
          mkdir -p "$nssdb"

          if [ ! -f "$nssdb/cert9.db" ]; then
            certutil -N -d "sql:$nssdb" --empty-password
          fi

          certutil -D -d "sql:$nssdb" -n "Caddy Local Authority" >/dev/null 2>&1 || true
          certutil -A -d "sql:$nssdb" -n "Caddy Local Authority" -t "CT,C,C" -i "$root_ca"
        '';
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

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
          {
            name = "Roam";
            url = "https://ro.am";
          }
          {
            name = "CCFlare";
            url = "https://ccflare.localhost";
          }
        ];
    };
  };
in
if isHeadless then base else lib.recursiveUpdate base desktop
