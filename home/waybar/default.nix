{ pkgs, config, repoRoot, ... }:
let
  waybarSourceDir = "${repoRoot}/home/waybar";
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    settings = [ ];
    style = null;
  };

  xdg.configFile."waybar/config" = {
    source = config.lib.file.mkOutOfStoreSymlink "${waybarSourceDir}/config.jsonc";
    onChange = ''
      ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
    '';
  };

  xdg.configFile."waybar/style.css" = {
    source = config.lib.file.mkOutOfStoreSymlink "${waybarSourceDir}/style.css";
    onChange = ''
      ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
    '';
  };
}
