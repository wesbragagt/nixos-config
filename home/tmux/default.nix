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
    (pkgs.writeShellApplication {
      name = "tmux-rename-session-for-cwd";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.tmux
      ];
      text = ''
        if [[ -z "''${TMUX:-}" ]]; then
          exit 0
        fi

        path="$(realpath -m "''${1:-$PWD}")"
        base="$(basename "$path")"
        parent="$(basename "$(dirname "$path")")"

        if [[ "$path" == "$HOME" || -z "$parent" || "$parent" == "/" ]]; then
          session="$base"
        else
          session="$parent/$base"
        fi

        current="$(tmux display-message -p '#S')"
        if [[ "$current" != "$session" ]]; then
          tmux rename-session "$session" 2>/dev/null || true
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
