{ pkgs, lib, config, inputs, ... }:
{
  home.sessionVariables = {
    NPM_GLOBAL = "$HOME/.npm-global";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    NIXOS_OZONE_WL = "1";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
  ];

  home.packages = with pkgs; [
    # wayland / audio
    pavucontrol
    wl-clipboard
    cliphist
    wlr-randr
    libnotify

    # screenshot / recording
    grim
    slurp
    swappy
    wf-recorder

    # network
    networkmanagerapplet
    iwgtk

    # browsers
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # cli tools
    inputs.exacli.packages.${pkgs.stdenv.hostPlatform.system}.default
    gh
    jq
    yq-go
    fd
    sesh

    # secrets / auth
    bitwarden-desktop
    bitwarden-cli
    libsecret

    # desktop / ui
    gtk3
    nwg-dock-hyprland
    waypaper
    swww

    # media
    mpv
    imv

    # data
    csvlens     # interactive CSV viewer
    duckdb      # in-process analytical SQL
    harlequin   # terminal database UI

    # git
    lazygit
    delta

    # scripts
    (pkgs.writeShellScriptBin "rofi-freq" (builtins.readFile ../scripts/rofi-freq.sh))
    (pkgs.writeShellScriptBin "sf" (builtins.readFile ../scripts/sf.sh))
    (pkgs.writeShellScriptBin "sgrep" (builtins.readFile ../scripts/sg.sh))
    (pkgs.writeShellScriptBin "battery-estimate" (builtins.readFile ../scripts/battery-estimate.sh))
    (pkgs.writeShellScriptBin "wf-record" (builtins.readFile ../scripts/wf-recorder.sh))
    (pkgs.callPackage ../pkgs/workmux {})
  ];


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
      gitd = "lazygit";
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

  programs.git = {
    enable = true;
    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };
  };

  programs.lazygit = {
    enable = true;
    settings.git.pagers = [
      { pager = "delta --dark --paging=never --line-numbers"; }
    ];
  };

  programs.obsidian = {
    enable = true;
    vaults."notes-live-sync" = {
      target = "notes-live-sync";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

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
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/jpeg"      = "imv.desktop";
      "image/png"       = "imv.desktop";
      "image/gif"       = "imv.desktop";
      "image/webp"      = "imv.desktop";
      "image/bmp"       = "imv.desktop";
      "image/tiff"      = "imv.desktop";
      "image/svg+xml"   = "imv.desktop";
      "video/mp4"       = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm"      = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/x-flv"     = "mpv.desktop";
    };
  };

  xdg.configFile = {
    "rofi/launchers/type-2/style-1.rasi".source = ../rofi/launchers/type-2/style-1.rasi;
    "rofi/launchers/type-2/shared/colors.rasi".source = ../rofi/launchers/type-2/shared/colors.rasi;
    "rofi/launchers/type-2/shared/fonts.rasi".source = ../rofi/launchers/type-2/shared/fonts.rasi;
    "rofi/colors/catppuccin.rasi".source = ../rofi/colors/catppuccin.rasi;
    "workmux/config.yaml".text = "nerdfont: true\n";
    "swappy/config".text = ''
      [Default]
      early_exit=true
      auto_save=true
      save_dir=$HOME/Screenshots
    '';
    "waypaper/config.ini".text = ''
      [Settings]
      language = en
      folder = /home/wesbragagt/Wallpapers
      monitors = All
      backend = swww
      fill = fill
      sort = name
      color = #ffffff
      subfolders = False
      show_hidden = False
      show_gifs_only = False
      number_of_columns = 3
      swww_transition_type = any
      swww_transition_step = 90
      swww_transition_angle = 0
      swww_transition_duration = 2
      swww_transition_fps = 60
      use_xdg_state = False
    '';
  };

  home.activation.createDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/Wallpapers
    mkdir -p $HOME/Screenshots
    mkdir -p $HOME/Videos
  '';
}
