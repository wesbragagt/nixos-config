{
  lib,
  repoRoot,
  config,
  hostProfile ? { },
  ...
}:
let
  sopsHostKeyPath = hostProfile.sopsHostKeyPath or null;
  useSystemSopsSecrets = sopsHostKeyPath != null;
  useHomeSopsSecrets = hostProfile.useHomeSopsSecrets or false;
  secretPath =
    systemPath: homePath:
    if useSystemSopsSecrets then
      systemPath
    else if useHomeSopsSecrets then
      homePath
    else
      "";
  exaApiKeyPath = secretPath "/run/secrets/exa_api_key" config.sops.secrets.exa_api_key.path;
  shellBootstrap = ''
    export NPM_GLOBAL="$HOME/.npm-global"
    export NPM_CONFIG_PREFIX="$NPM_GLOBAL"
    export PATH="$NPM_GLOBAL/bin:$PATH"

    if [[ -z "$SSH_AUTH_SOCK" && -S "$HOME/.bitwarden-ssh-agent.sock" ]]; then
      export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
    fi

    if [[ -n "${exaApiKeyPath}" && -f "${exaApiKeyPath}" ]]; then
      export EXA_API_KEY="$(< "${exaApiKeyPath}")"
    fi

    __nixos_flake_host() {
      local host
      host="$(hostname -s 2>/dev/null || hostname)"
      host="''${host%%.*}"

      if [[ -z "$host" ]]; then
        echo "Unable to determine current hostname for NixOS rebuild" >&2
        return 1
      fi

      echo "$host"
    }

    rebuild() {
      local action host
      action="''${1:-switch}"

      case "$action" in
        boot|build|dry-build|dry-activate|switch|test)
          shift
          ;;
        *)
          action="switch"
          ;;
      esac

      host="$(__nixos_flake_host)" || return
      echo "Rebuilding host '$host' with action '$action'..." >&2
      sudo nixos-rebuild "$action" --impure --flake ${repoRoot}#"$host" "$@"
    }

    cd/() {
      local repo_root
      repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
      cd "$repo_root"
    }

    cdl() {
      local selection dir
      selection=$(fzf --preview 'bat --style=numbers --color=always --line-range :500 {}') || return 0
      [[ -n "$selection" ]] || return 0

      sleep 0.3
      dir=$(dirname "$selection")
      [[ -n "$dir" ]] || return 0

      echo "Changing directory to $dir"
      cd "$dir"
    }
  '';
in
{
  sops.secrets = lib.optionalAttrs useHomeSopsSecrets {
    exa_api_key = { };
  };

  home.sessionVariables = {
    NPM_GLOBAL = "$HOME/.npm-global";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    EDITOR = "nvim";
    VISUAL = "nvim";
    MANPAGER = "nvim +Man!";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
  ];

  programs.bash = {
    enable = true;
    shellAliases = {
      sg = "$HOME/.nix-profile/bin/sg";
    };
    initExtra = shellBootstrap;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    historySubstringSearch.enable = true;
    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      share = true;
      extended = true;
    };
    shellAliases = {
      sg = "$HOME/.nix-profile/bin/sg";
      gs = "git status";
      gitd = "lazygit";
      # git add all changes and commit
      gg = "git add -A && git commit";
      # github cli command to push current branch to origin
      gpr = "git push -u origin HEAD";
      # github cli command to open pull request in browser
      got = "gh pr view";
    };
    initContent = shellBootstrap + ''
      autoload -Uz edit-command-line
      zle -N edit-command-line
      bindkey '^Y' autosuggest-accept
      bindkey '^P' up-line-or-history
      bindkey '^N' down-line-or-history
      bindkey '^X^E' edit-command-line
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ../../starship/zephyr.toml);
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    defaultCommand = "rg --files --hidden --follow --glob '!.git'";
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.ripgrep.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.activation.createDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/Wallpapers
    mkdir -p $HOME/Screenshots
    mkdir -p $HOME/Videos
  '';
}
