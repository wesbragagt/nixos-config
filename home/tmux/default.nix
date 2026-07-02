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
      name = "tmux-sesh-picker";
      runtimeInputs = [
        pkgs.fd
        pkgs.fzf
        pkgs.sesh
        pkgs.tmux
      ];
      text = ''
        # This script is launched from tmux with `env -u BASH_ENV ...`, so keep
        # the picker itself free of extra shell hops. fzf-tmux wraps popup mode in
        # `tmux popup ... "bash ..."`, which re-triggers our BASH_ENV/direnv hook
        # in repos with a .envrc. Native `fzf --tmux` avoids that extra bash.
        unset BASH_ENV

        selected="$(
          sesh list -t | fzf --tmux=center,90%,85%,border-native \
            --no-sort --ansi --border-label ' sesh ' --prompt '🪟  ' \
            --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
            --bind 'tab:down,btab:up' \
            --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
            --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
            --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' \
            --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
            --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 4 -t d -E .Trash . ~)' \
            --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(🪟  )+reload(sesh list -t)'
        )" || exit 0

        [[ -n "$selected" ]] || exit 0
        tmux-session-for-path "$selected"
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
