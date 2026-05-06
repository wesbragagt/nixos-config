{ lib, repoRoot, ... }:
let
  shellBootstrap = ''
    export NPM_GLOBAL="$HOME/.npm-global"
    export NPM_CONFIG_PREFIX="$NPM_GLOBAL"
    export PATH="$NPM_GLOBAL/bin:$PATH"

    rebuild() {
      sudo nixos-rebuild switch --impure --flake ${repoRoot}#"$(hostname)" "$@"
    }
  '';
in
{
  home.sessionVariables = {
    NPM_GLOBAL = "$HOME/.npm-global";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    EDITOR = "nvim";
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
      bindkey '^Y' autosuggest-accept
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
    defaultOptions = [ "--height=40%" "--layout=reverse" "--border" ];
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

  home.activation.createDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/Wallpapers
    mkdir -p $HOME/Screenshots
    mkdir -p $HOME/Videos
  '';
}
