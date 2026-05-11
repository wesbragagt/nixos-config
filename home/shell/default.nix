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
  secretPath = systemPath: homePath:
    if useSystemSopsSecrets then
      systemPath
    else if useHomeSopsSecrets then
      homePath
    else
      "";
  exaApiKeyPath = secretPath "/run/secrets/exa_api_key" config.sops.secrets.exa_api_key.path;
  bwClientIdPath = secretPath "/run/secrets/bw_client_id" config.sops.secrets.bw_client_id.path;
  bwClientSecretPath = secretPath "/run/secrets/bw_client_secret" config.sops.secrets.bw_client_secret.path;
  bwScopePath = secretPath "/run/secrets/bw_scope" config.sops.secrets.bw_scope.path;
  bwGrantTypePath = secretPath "/run/secrets/bw_grant_type" config.sops.secrets.bw_grant_type.path;
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

    if [[ -n "${bwClientIdPath}" && -f "${bwClientIdPath}" ]]; then
      export BW_CLIENTID="$(< "${bwClientIdPath}")"
    fi

    if [[ -n "${bwClientSecretPath}" && -f "${bwClientSecretPath}" ]]; then
      export BW_CLIENTSECRET="$(< "${bwClientSecretPath}")"
    fi

    if [[ -n "${bwScopePath}" && -f "${bwScopePath}" ]]; then
      export BW_SCOPE="$(< "${bwScopePath}")"
    fi

    if [[ -n "${bwGrantTypePath}" && -f "${bwGrantTypePath}" ]]; then
      export BW_GRANT_TYPE="$(< "${bwGrantTypePath}")"
    fi

    bw-login-api() {
      bw login --apikey "$@"
    }

    rebuild() {
      sudo nixos-rebuild switch --impure --flake ${repoRoot}#"$(hostname)" "$@"
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
    bw_client_id = { key = "bitwarden/client_id"; };
    bw_client_secret = { key = "bitwarden/client_secret"; };
    bw_scope = { key = "bitwarden/scope"; };
    bw_grant_type = { key = "bitwarden/grant_type"; };
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
      nvimh = "nvim --headless";
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
      gs = "git status";
      sg = "sgrep";
      gitd = "lazygit";
      nvimh = "nvim --headless";
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
