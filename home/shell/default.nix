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
  exaApiKeyPath =
    if useSystemSopsSecrets then
      "/run/secrets/exa_api_key"
    else if useHomeSopsSecrets then
      config.sops.secrets.exa_api_key.path
    else
      "";
  shellBootstrap = ''
    export NPM_GLOBAL="$HOME/.npm-global"
    export NPM_CONFIG_PREFIX="$NPM_GLOBAL"
    export PATH="$NPM_GLOBAL/bin:$PATH"

    if [[ -n "${exaApiKeyPath}" && -f "${exaApiKeyPath}" ]]; then
      export EXA_API_KEY="$(< "${exaApiKeyPath}")"
    fi

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
