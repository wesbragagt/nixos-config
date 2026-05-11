{ pkgs, inputs, ... }:
{
  imports = [
    ./repo-root.nix
    ./claude
    ./hyprland
    ./waybar
    ./zen
    ./programs.nix
    ./tmux
    ./neovim
    ./swaync.nix
    ./sops
    inputs.zen-browser.homeModules.beta
    inputs.chromium-webapps.homeManagerModules.default
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.username = "wesbragagt";
  home.homeDirectory = "/home/wesbragagt";
  home.stateVersion = "25.11";

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
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

  programs.home-manager.enable = true;

  wes.claudeCode = {
    enable = true;
    aliases = {
      ccd = "claude --dangerously-skip-permissions";
    };
  };

  programs.chromium-webapps = {
    enable = true;
    webApps =
      let
        papirusIcon = name:
          "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/${name}.svg";
      in [
        {
          name = "Spotify";
          url = "https://open.spotify.com";
          icon = papirusIcon "com.spotify.Client";
        }
        {
          name = "ro.am";
          url = "https://ro.am";
          icon = pkgs.fetchurl {
            url = "https://ro.am/website/android-chrome-512x512.png";
            hash = "sha256-XxZBH+r0tk1FDL9LTNuJIAka8UUVJeOYTovWCKEMC6Y=";
          };
        }
      ];
  };
}
