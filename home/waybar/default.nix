{
  pkgs,
  config,
  repoRoot,
  hostProfile ? { },
  ...
}:
let
  waybarSourceDir = "${repoRoot}/home/waybar";
  isLaptop = hostProfile.isLaptop or false;
  waybarConfig = if isLaptop then "config.jsonc" else "config-desktop.jsonc";
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    settings = [ ];
    style = null;
  };

  xdg.configFile."waybar/config" = {
    source = config.lib.file.mkOutOfStoreSymlink "${waybarSourceDir}/${waybarConfig}";
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
