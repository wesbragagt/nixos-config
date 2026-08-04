{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "tmux-new-session-prompt";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.tmux
      ];
      text = ''
        cwd="''${1:-$PWD}"

        old_tty="$(stty -g 2>/dev/null || true)"
        restore_tty() {
          if [[ -n "$old_tty" ]]; then
            stty "$old_tty" 2>/dev/null || true
          fi
        }

        trap 'restore_tty; exit 0' INT TERM
        trap restore_tty EXIT

        printf '\033[1mNew tmux session\033[0m\n\n'
        printf 'Name: '

        session=""
        stty -echo -icanon min 1 time 0 2>/dev/null || true

        while IFS= read -rsn1 key; do
          case "$key" in
            $'\e')
              exit 0
              ;;
            "")
              break
              ;;
            $'\177' | $'\b')
              if [[ "''${#session}" -gt 0 ]]; then
                session="''${session%?}"
                printf '\b \b'
              fi
              ;;
            $'\003' | $'\004')
              exit 0
              ;;
            *)
              if [[ "$key" =~ [[:print:]] ]]; then
                session+="$key"
                printf '%s' "$key"
              fi
              ;;
          esac
        done

        printf '\n'
        restore_tty
        trap - EXIT

        session="''${session#"''${session%%[![:space:]]*}"}"
        session="''${session%"''${session##*[![:space:]]}"}"

        if [[ -z "$session" ]]; then
          exit 0
        fi

        if [[ "$session" == *:* ]]; then
          tmux display-message "Session names cannot contain ':'"
          exit 1
        fi

        if tmux has-session -t "=$session" 2>/dev/null; then
          tmux switch-client -t "=$session"
          exit 0
        fi

        tmux new-session -d -s "$session" -c "$cwd"
        tmux switch-client -t "=$session"
      '';
    })
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
