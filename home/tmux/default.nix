{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ./tmux.conf;
    plugins = with pkgs.tmuxPlugins; [
      nord
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-dir '~/.cache/tmux/resurrect'
          set -g @resurrect-delete-backup-after '7'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];
  };
}
