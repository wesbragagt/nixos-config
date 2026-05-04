{ pkgs, ... }:
{
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./programs.nix
  ];

  home.username = "wesbragagt";
  home.homeDirectory = "/home/wesbragagt";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
