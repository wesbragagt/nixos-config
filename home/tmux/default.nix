{ pkgs, lib, config, repoRoot, ... }:
let
  tmuxSourceDir = "${repoRoot}/home/tmux";
in
{
  programs.tmux.enable = true;

  xdg.configFile."tmux/tmux.conf" = lib.mkForce {
    source = config.lib.file.mkOutOfStoreSymlink "${tmuxSourceDir}/tmux.conf";
  };

  xdg.configFile."tmux/plugins/nord.tmux".source = pkgs.tmuxPlugins.nord.rtp;
}
