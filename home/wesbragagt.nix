{ pkgs, inputs, ... }:
{
  imports = [
    ./repo-root.nix
    ./hyprland
    ./waybar
    ./programs.nix
    ./tmux
    ./neovim
    ./swaync.nix
    ./sops
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

  programs.chromium-webapps = {
    enable = true;
    webApps =
      let
        papirusIcon = name:
          "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/${name}.svg";
      in [
        {
          name = "Slack";
          url = "https://app.slack.com";
          icon = papirusIcon "com.slack.Slack";
        }
        {
          name = "Spotify";
          url = "https://open.spotify.com";
          icon = papirusIcon "com.spotify.Client";
        }
      ];
  };
}
