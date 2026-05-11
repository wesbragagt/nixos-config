{ pkgs, inputs, ... }:
let
  bookmarks = import ./bookmarks.nix;
in
{
  programs.zen-browser = {
    enable = true;
    profiles.default = {
      extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
        bitwarden
      ];
      spaces = {
        Work = {
          id = "d62a8df9-3310-43e2-a1a1-7f318100f001";
          position = 1000;
          icon = "💼";
        };
        Personal = {
          id = "4db60f4f-d3b0-46f7-9d8e-f7cf77f8d002";
          position = 2000;
          icon = "🏡";
        };
      };
      bookmarks = bookmarks;
    };
  };

  xdg.configFile."zen/bookmarks.json".text = builtins.toJSON bookmarks.settings;
}
