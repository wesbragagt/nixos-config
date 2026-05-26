{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "tmux-session-for-path";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.sesh
        pkgs.tmux
      ];
      text = ''
        input="''${1:-}"

        if [[ -z "$input" ]]; then
          exit 0
        fi

        expanded="''${input/#\~/$HOME}"

        if [[ ! -d "$expanded" ]]; then
          exec sesh connect "$input"
        fi

        path="$(realpath -m "$expanded")"
        base="$(basename "$path")"
        parent="$(basename "$(dirname "$path")")"

        if [[ "$path" == "$HOME" || -z "$parent" || "$parent" == "/" ]]; then
          session="$base"
        else
          session="$parent/$base"
        fi

        if ! tmux has-session -t "$session" 2>/dev/null; then
          tmux new-session -d -s "$session" -c "$path"
        fi

        if [[ -n "''${TMUX:-}" ]]; then
          tmux switch-client -t "$session"
        else
          tmux attach-session -t "$session"
        fi
      '';
    })
  ];

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
