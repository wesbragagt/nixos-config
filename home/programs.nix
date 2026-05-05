{ pkgs, config, inputs, ... }:
{
  home.sessionVariables = {
    NPM_GLOBAL = "$HOME/.npm-global";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
  ];

  home.packages = with pkgs; [
    pavucontrol
    grim
    slurp
    wl-clipboard
    networkmanagerapplet
    iwgtk
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.exacli.packages.${pkgs.stdenv.hostPlatform.system}.default
    bitwarden-desktop
    bitwarden-cli
    gh
    gtk3
    jq
    yq-go
    (pkgs.writeShellScriptBin "rofi-freq" (builtins.readFile ../scripts/rofi-freq.sh))
    (pkgs.writeShellScriptBin "sf" (builtins.readFile ../scripts/sf.sh))
    (pkgs.writeShellScriptBin "sgrep" (builtins.readFile ../scripts/sg.sh))
    (pkgs.writeShellScriptBin "battery-estimate" (builtins.readFile ../scripts/battery-estimate.sh))
    (pkgs.writeShellScriptBin "spotify-webapp" ''
      exec ${pkgs.chromium}/bin/chromium \
        --ozone-platform=wayland \
        --app=https://open.spotify.com/ \
        --class=Spotify \
        --name=Spotify \
        "$@"
    '')
    nwg-dock-hyprland
    sesh
    fd
    cliphist
    wlr-randr
  ];

  programs.chromium = {
    enable = true;
    commandLineArgs = [ "--ozone-platform=wayland" ];
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = false;
    };
  };

  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=12";
      };
      colors.alpha = 0.8;
    };
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      export NPM_GLOBAL="$HOME/.npm-global"
      export NPM_CONFIG_PREFIX="$NPM_GLOBAL"
      export PATH="$NPM_GLOBAL/bin:$PATH"

      rebuild() {
        sudo nixos-rebuild switch --impure --flake ~/nixos-config#"$(hostname)" "$@"
      }
    '';
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
      ll = "ls -lah";
      gs = "git status";
      sg = "sgrep";
    };
    initContent = ''
      export NPM_GLOBAL="$HOME/.npm-global"
      export NPM_CONFIG_PREFIX="$NPM_GLOBAL"
      export PATH="$NPM_GLOBAL/bin:$PATH"

      rebuild() {
        sudo nixos-rebuild switch --impure --flake ~/nixos-config#"$(hostname)" "$@"
      }
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ../starship/zephyr.toml);
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

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    terminal = "xterm-256color";
    escapeTime = 0;
    historyLimit = 3000;
    baseIndex = 1;
    mouse = true;
    prefix = "C-Space";
    plugins = [ pkgs.tmuxPlugins.nord ];
    extraConfig = ''
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      set-option -ga terminal-overrides ",xterm-256color:Tc"
      set-option -g status-position top
      set -g extended-keys on
      set -g extended-keys-format csi-u

      bind-key x kill-pane
      set -g detach-on-destroy off

      bind-key c new-window -c "#{pane_current_path}"
      bind-key % split-window -h -c "#{pane_current_path}"
      bind-key '"' split-window -v -c "#{pane_current_path}"

      set-option -sg escape-time 10
      set-option -g focus-events on

      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'wl-copy'

      bind -r i resizep -x 50

      # Smart pane switching with awareness of Vim splits.
      # See: https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"

      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      bind-key -n 'C-\' if-shell "$is_vim" 'send-keys C-\\\\' 'select-pane -l'

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l

      bind C-p display-popup "zsh"

      # sesh + fzf session picker
      bind-key "Space" run-shell "sesh connect \"$(
          sesh list | fzf-tmux -p 55%,60% \
              --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
              --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
              --bind 'tab:down,btab:up' \
              --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
              --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
              --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' \
              --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
              --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
              --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)'
      )\""

      bind-key d new-window -n "revdiff:#{b:pane_current_path}" "revdiff"

      set-option -g status-right ""
      set -g status-left-length 100
    '';
  };
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "${pkgs.foot}/bin/foot";
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      drun-display-format = "{name}";
    };
    theme = "${config.xdg.configHome}/rofi/launchers/type-2/style-1.rasi";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github_key.pub";
        extraOptions = {
          IdentityAgent = "~/.bitwarden-ssh-agent.sock";
        };
      };
    };
  };

  home.file.".cache/nwg-dock-pinned".text = ''
    foot
    chromium-browser
    thunar
    Spotify
  '';

  home.file.".local/share/icons/hicolor/scalable/apps/spotify.svg".source = ../assets/spotify.svg;

  xdg.desktopEntries.spotify = {
    name = "Spotify";
    exec = "spotify-webapp";
    icon = "spotify";
    terminal = false;
    categories = [ "AudioVideo" "Audio" "Player" "Network" ];
    settings.StartupWMClass = "Spotify";
  };

  xdg.configFile = {
    "rofi/launchers/type-2/style-1.rasi".source = ../rofi/launchers/type-2/style-1.rasi;
    "rofi/launchers/type-2/shared/colors.rasi".source = ../rofi/launchers/type-2/shared/colors.rasi;
    "rofi/launchers/type-2/shared/fonts.rasi".source = ../rofi/launchers/type-2/shared/fonts.rasi;
    "rofi/colors/catppuccin.rasi".source = ../rofi/colors/catppuccin.rasi;
  };

}
