{ config, inputs, repoRoot, ... }:
let
  yaziSourceDir = "${repoRoot}/home/yazi/config";
in
{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  xdg.configFile = {
    "yazi/yazi.toml".source = config.lib.file.mkOutOfStoreSymlink "${yaziSourceDir}/yazi.toml";
    "yazi/theme.toml".source = config.lib.file.mkOutOfStoreSymlink "${yaziSourceDir}/theme.toml";
    "yazi/flavors/tokyo-night.yazi".source = inputs.tokyo-night-yazi;
  };
}
